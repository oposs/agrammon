use v6;
use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Cro::HTTP::Session::InMemory;
use DB::Pg;

use Agrammon::Config;
use Agrammon::DataSource::CSV;
use Agrammon::Documentation;
use Agrammon::ModelCache;
use Agrammon::OutputFormatter::CSV;
use Agrammon::OutputFormatter::Text;
use Agrammon::Performance;
use Agrammon::ResultCollector;
use Agrammon::TechnicalParser;
use Agrammon::Web::Routes;
use Agrammon::Web::SessionStore;
use Agrammon::Web::SessionUser;


my %*SUB-MAIN-OPTS =
  :named-anywhere,    # allow named variables at any location
;

subset ExistingFile of Str where { .IO.e or note("No such file $_") && exit 1 }
subset SupportedLanguage of Str where { $_ ~~ /^ de|en|fr $/ or note("ERROR: --language=[de|en|fr]") && exit 1 };
subset SortOrder of Str where { $_ ~~ /^ model|calculation $/ or note("ERROR: --sort=[model|calculation]") && exit 1 };

#| Start the web interface
multi sub MAIN('web', ExistingFile $cfg-filename, ExistingFile $model-filename, Str $tech-file?) is export {
    my $http = web($cfg-filename, $model-filename, $tech-file);
    react {
        whenever signal(SIGINT) {
            say "Shutting down...";
            $http.stop;
            done;
        }
    }
}

#| Run the model
multi sub MAIN('run', ExistingFile $filename, ExistingFile $input, Str $tech-file?,
               SupportedLanguage :$language = 'de', Str :$prints = 'All', Str :$variants = 'SHL',
               Bool :$csv, Bool :$include-filters, Int :$batch=1, Int :$degree=4, Int :$max-runs
              ) is export {
    my %results = run $filename.IO, $input.IO, $tech-file, $variants, $language, $prints, $csv, $include-filters,
            $batch, $degree, $max-runs;
    say "##  Model: $filename";
    say "##  Variants: $variants";
    for %results.keys -> $simulation {
        say "### Simulation $simulation";
        say "##  Print filter: $prints";
        for %results{$simulation}.keys.sort -> $dataset {
            say "#   Dataset $dataset";
            say %results{$simulation}{$dataset};
        }
    }
}

#| Dump model
multi sub MAIN('dump', ExistingFile $filename, Str :$variants = 'SHL', SortOrder :$sort = 'model') is export {
    say chomp dump-model $filename.IO, $variants, $sort;
}

multi sub MAIN('latex', ExistingFile $filename, Str $tech-file?, Str :$variants = 'SHL', SortOrder :$sort = 'model') is export {
    latex $filename.IO, $tech-file, $variants, $sort;
}

#| Create LaTeX docu
sub latex (IO::Path $path, $tech-file, $variants, $sort) is export {
    die "ERROR: latex expects a .nhd file" unless $path.extension eq 'nhd';

    my $module-path = $path.parent;
    my $module-file = $path.basename;
    my $module      = $path.extension('').basename;

    my $tech-input = $tech-file // $module-path.add('technical.cfg');
    my $params = parse-technical( $tech-input.IO.slurp );
    $path.dirname ~~ / .* '/' (.+) /;
    my $model-name = ~$0;
    my $model = timed "Load $module of $module-path from cache", {
        load-model-using-cache( $*HOME.add('.agrammon'), $module-path, $module, preprocessor-options($variants));
    };

    say create-latex-source(
        $model-name,
        $model,
        $sort,
        technical => %($params.technical.map(-> %module {
            %module.keys[0] => %(%module.values[0].map({ .name => .value }))
        }))
    );

}

#| Create Agrammon user
multi sub MAIN('create-user', Str $username, Str $firstname, Str $lastname) is export {
    say "Will create Agrammon user; NYI";
}

sub USAGE() is export {
    say "$*USAGE\n" ~ chomp q:to/USAGE/;
        See https://www.agrammon.ch for more information about Agrammon.
    USAGE
}


sub dump-model (IO::Path $path, $variants, $sort) is export {
    die "ERROR: dump expects a .nhd file" unless $path.extension eq 'nhd';

    my $module-path = $path.parent;
    my $module-file = $path.basename;
    my $module      = $path.extension('').basename;

    my $model = timed "load $module", {
        load-model-using-cache($*HOME.add('.agrammon'), $module-path, $module, preprocessor-options($variants));
    };
    return $model.dump($sort);
}

sub run (IO::Path $path, IO::Path $input-path, $tech-file, $variants, $language, $prints, Bool $csv, Bool $include-filters,
        $batch, $degree, $max-runs) is export {
    die "ERROR: run expects a .nhd file" unless $path.extension eq 'nhd';

    my $module-path = $path.parent;
    my $module-file = $path.basename;
    my $module      = $path.extension('').basename;

    my $tech-input = $tech-file // $module-path.add('technical.cfg');
    my %technical-parameters = timed "Load parameters from $tech-input", {
        my $params = parse-technical( $tech-input.IO.slurp );
        %($params.technical.map(-> %module {
                %module.keys[0] => %(%module.values[0].map({ .name => .value }))
        }));
    }

    my $model = timed "Load $module", {
        load-model-using-cache($*HOME.add('.agrammon'), $module-path, $module, preprocessor-options($variants));
    };

    my $filename = $input-path;
    my $fh = open $filename, :r
          or die "Couldn't open file $filename for reading";
    LEAVE $fh.?close;
    my $ds = Agrammon::DataSource::CSV.new;

    my $rc = Agrammon::ResultCollector.new;
    my atomicint $n = 0;
    my %results;
    my class X::EarlyFinish is Exception {}
    race for $ds.read($fh).race(:$batch, :$degree) -> $dataset {
        my $my-n = ++⚛$n;

        my $outputs = timed "$my-n: Run $filename", {
            $model.run(
                input     => $dataset,
                technical => %technical-parameters,
            );
        }

        timed "Create output", {
            my $result;
            if ($csv) {
                die "CSV output including filters is not yet supported" if $include-filters;
                $result = output-as-csv($dataset.simulation-name, $dataset.dataset-id, $model, $outputs, $language);
            }
            else {
                $result = output-as-text($model, $outputs, $language, $prints, $include-filters);
            }
            $rc.add-result($dataset.simulation-name, $dataset.dataset-id, $result);
        }
        if $max-runs and $my-n == $max-runs {
            note "Finished after $my-n datasets";
            die X::EarlyFinish.new;
        };
    }
    return $rc.results;
    CATCH {
        when X::EarlyFinish { return $rc.results }
    }
}

sub web(Str $cfg-filename, Str $model-filename, Str $tech-file?) is export {

    # initialization
    my $cfg = Agrammon::Config.new;
    note "Loading config from $cfg-filename";
    $cfg.load($cfg-filename);
    my $variants = $cfg.model-variants;

    my $model-path = $model-filename.IO;
    die "ERROR: web expects a .nhd file" unless $model-path.extension eq 'nhd';

    note "Running model variant $variants from $model-path";
    my $module-path = $model-path.parent;
    my $module-file = $model-path.basename;
    my $module = $model-path.IO.extension('').basename;
    my $tech-input = $tech-file // $module-path.add('technical.cfg');
    my %technical-parameters = timed "Load parameters from $tech-input", {
        my $params = parse-technical($tech-input.IO.slurp);
        %($params.technical.map(-> %module {
            %module.keys[0] => %(%module.values[0].map({ .name => .value }))
        }));
    }

    my $model = timed "Load model from $module-path/$module.nhd", {
        load-model-using-cache($*HOME.add('.agrammon'), $module-path, $module, preprocessor-options($variants));
    }

    my $db = DB::Pg.new(conninfo => $cfg.db-conninfo);
    PROCESS::<$AGRAMMON-DB-CONNECTION> = $db;

    my $ws = Agrammon::Web::Service.new(:$cfg, :$model, :%technical-parameters);

    # setup and start web server
    my $host = %*ENV<AGRAMMON_HOST> || '0.0.0.0';
    my $port = %*ENV<AGRAMMON_PORT> || 20000;
    my Cro::Service $http = Cro::HTTP::Server.new(
        :$host, :$port,
        application => routes($ws),
        after => [
            Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
        ],
        before => [
            Agrammon::Web::SessionStore.new(:$db)
        ]
    );
    $http.start;
    say "Listening at http://$host:$port";
    return $http;
}

sub preprocessor-options(Str $variants) {
    set($variants.split(","));
}
