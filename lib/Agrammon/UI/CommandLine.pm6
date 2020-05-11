use v6;
use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Cro::HTTP::Session::InMemory;
use DB::Pg;

use Agrammon::Config;
use Agrammon::DataSource::CSV;
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
subset SupportedLanguage of Str where { $_ ~~ /de|en|fr/ or note("ERROR: --language=[de|en|fr]") && exit 1 };

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
               SupportedLanguage :$language = 'de', Str :$prints = 'All',
               Bool :$csv, Int :$batch=1, Int :$degree=4, Int :$max-runs
              ) is export {
    my %results = run $filename.IO, $input.IO, $tech-file, $language, $prints, $csv, $batch, $degree, $max-runs;
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
multi sub MAIN('dump', ExistingFile $filename) is export {
    say chomp dump $filename.IO;
}

#| Create LaTeX docu
multi sub MAIN('latex', ExistingFile $filename) is export {
    say "Will create LaTeX docu; NYI";
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


sub dump (IO::Path $path) is export {
    die "ERROR: dump expects a .nhd file" unless $path.extension eq 'nhd';

    my $module-path = $path.parent;
    my $module-file = $path.basename;
    my $module      = $path.extension('').basename;

    my $model = timed "load $module", { load-model-using-cache($*HOME.add('.agrammon'), $module-path, $module) };
    return $model.dump;
}

sub run (IO::Path $path, IO::Path $input-path, $tech-file, $language, $prints, Bool $csv, $batch, $degree, $max-runs)  is export {
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
        load-model-using-cache($*HOME.add('.agrammon'), $module-path, $module)
    }

    my $filename = $input-path;
    my $fh = open $filename, :r
          or die "Couldn't open file $filename for reading";
    LEAVE $fh.close;
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
                $result = output-as-csv($dataset.simulation-name, $dataset.dataset-id, $model, $outputs, $language);
            }
            else {
                $result = output-as-text($model, $outputs, $language, $prints);
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
    $cfg.load($cfg-filename);

    my $model-path = $model-filename.IO;
    die "ERROR: web expects a .nhd file" unless $model-path.extension eq 'nhd';

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

    my $model = timed "Load $module", {
        load-model-using-cache($*HOME.add('.agrammon'), $module-path, $module)
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
