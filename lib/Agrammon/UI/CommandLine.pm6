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
use Agrammon::TechnicalParser;
use Agrammon::Web::Routes;
use Agrammon::Web::SessionUser;

sub dump (IO::Path $path) is export {
    die "ERROR: dump expects a .nhd file" unless $path.extension eq 'nhd';

    my $module-path = $path.parent;
    my $module-file = $path.basename;
    my $module      = $path.extension('').basename;

    my $model = timed "load $module", { load-model-using-cache($*HOME.add('.agrammon'), $module-path, $module) };
    return $model.dump;
}

sub run (IO::Path $path, IO::Path $input-path, $tech-file, $language, $prints, Bool $csv)  is export {
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

sub web(Str $cfg-filename, Str $model-filename, Str $tech-file?) is export {

    # initialization
    my $cfg = Agrammon::Config.new;
    $cfg.load($cfg-filename);

    my $model-path = $model-filename.IO;
    die "ERROR: web expects a .nhd file" unless $model-path.extension eq 'nhd';

    my $module-path = $model-path.parent;
    my $module-file = $model-path.basename;
    my $module      = $model-path.IO.extension('').basename;

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

    PROCESS::<$AGRAMMON-DB-CONNECTION> = DB::Pg.new(conninfo => $cfg.db-conninfo);
                              
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
            Cro::HTTP::Session::InMemory[Agrammon::Web::SessionUser].new(
                expiration  => Duration.new(60 * 15),
            )
        ]
    );
    $http.start;
    say "Listening at http://$host:$port";
    return $http;
}
