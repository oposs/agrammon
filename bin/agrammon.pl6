#!/usr/bin/env perl6

use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Cro::HTTP::Session::InMemory;
use DB::Pg;

use Agrammon::Config;
use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::ModelCache;
use Agrammon::Web::Routes;
use Agrammon::Web::SessionUser;
use Agrammon::TechnicalParser;
use Agrammon::OutputFormatter::CSV;
use Agrammon::OutputFormatter::Text;

my %*SUB-MAIN-OPTS =
  :named-anywhere,    # allow named variables at any location 
;

subset ExistingFile of Str where { .IO.e or note("No such file $_") && exit 1 }
subset SupportedLanguage of Str where { $_ ~~ /de|en|fr/ or note("ERROR: --language=[de|en|fr]") && exit 1 };

#| Start the web interface
multi sub MAIN('web', ExistingFile $filename) {
    # initialization
    my $cfg-file = $filename;
    my $cfg = Agrammon::Config.new;
    $cfg.load($cfg-file);

    PROCESS::<$AGRAMMON-DB-CONNECTION> = DB::Pg.new(conninfo => $cfg.db-conninfo);
                              
    my $ws = Agrammon::Web::Service.new(
        cfg  => $cfg
    );

    # setup and start web server
    my $host = %*ENV<AGRAMMON_HOST> || '0.0.0.0';
    my $port = %*ENV<AGRAMMON_PORT> || 20000;
    my Cro::Service $http = Cro::HTTP::Server.new(
        host => $host,
        port => $port,
        application => routes($ws),
        after => [
            Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
        ],
        before => [
            Cro::HTTP::Session::InMemory[Agrammon::Web::SessionUser].new(
                expiration  => Duration.new(60 * 15),
            )
        ]
    );
    $http.start;
    say "Listening at http://$host:$port";
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
               Bool :$csv
              ) {
    my %results = run $filename.IO, $input.IO, $tech-file, $language, $prints, $csv;
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
multi sub MAIN('dump', ExistingFile $filename) {
    say chomp dump $filename.IO;
}

#| Create LaTeX docu
multi sub MAIN('latex', ExistingFile $filename) {
    say "Will create LaTeX docu; NYI";
}

#| Create Agrammon user
multi sub MAIN('create-user', Str $username, Str $firstname, Str $lastname) {
    say "Will create Agrammon user; NYI";
}

sub USAGE() {
    say "$*USAGE\n" ~ chomp q:to/USAGE/;
        See https://www.agrammon.ch for more information about Agrammon.
    USAGE
}

sub run (IO::Path $path, IO::Path $input-path, $tech-file, $language, $prints, Bool $csv) {
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
    my $fh = open $filename, :r, :!chomp
            or die "Couldn't open file $filename for reading";
    LEAVE $fh.close;
    my $ds = Agrammon::DataSource::CSV.new;
    my @datasets = timed "Load $filename", {
        $ds.read($fh);
    }
    note "Found " ~ @datasets.elems ~ ' dataset(s)';

    my %results;
    for @datasets -> $dataset {
        my $outputs = timed "Run $filename", {
            $model.run(
                input     => $dataset,
                technical => %technical-parameters,
            );
        }

        my $result;
        if ($csv) {
            $result = output-as-csv($dataset.simulation-name, $dataset.dataset-id, $model, $outputs, $language);
        }
        else {
            $result = output-as-text($model, $outputs, $language, $prints);
        }
        %results{$dataset.simulation-name}{$dataset.dataset-id} = $result;
    }
    return %results;
}

sub dump (IO::Path $path) {
    die "ERROR: dump expects a .nhd file" unless $path.extension eq 'nhd';

    my $module-path = $path.parent;
    my $module-file = $path.basename;
    my $module      = $path.extension('').basename;

    my $model = load-model-using-cache($*HOME.add('.agrammon'), $module-path, $module);
    return $model.dump;
}

sub timed(Str $title, &proc) {
    my $start = now;
    my \ret   = proc;
    my $end   = now;
    note sprintf "$title ran %.3f seconds", $end-$start;
    return ret;
}
