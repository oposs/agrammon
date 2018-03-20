#!/usr/bin/env perl6

use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Cro::HTTP::Session::InMemory;
use DB::Pg;

use Agrammon::Config;
use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::Web::Routes;
use Agrammon::Web::SessionUser;

my %*SUB-MAIN-OPTS =
  :named-anywhere,    # allow named variables at any location 
;

subset ExistingFile of Str where { .IO.e or note("No such file $_") && exit 1 }

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
multi sub MAIN('run', ExistingFile $filename, ExistingFile $input) {
    say run $filename.IO, $input.IO;
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

sub run (IO::Path $path, IO::Path $input-path) {
    die "ERROR: run expects a .nhd file" unless $path.extension eq 'nhd';

    my $module-path = $path.parent;
    my $module-file = $path.basename;
    my $module      = $path.extension('').basename;

    say "module-path=$module-path";
    my $model = Agrammon::Model.new(path => $module-path);
    $model.load($module);

    my $filename = $input-path;
    say "filename=$filename";
    my $fh = open $filename, :r, :!chomp
            or die "Couldn't open file $filename for reading";
#    LEAVE $fh.close;

    my $ds = Agrammon::DataSource::CSV.new;

    my @datasets = $ds.read($fh);
    say "Found " ~ @datasets.elems ~ ' datasets';

    my %outputs = $model.run(
        input => @datasets[0]
    );
    dd %outputs;
    return %outputs;
}

sub load {
    ...
}

sub dump (IO::Path $path) {
    die "ERROR: dump expects a .nhd file" unless $path.extension eq 'nhd';

    my $module-path = $path.parent;
    my $module-file = $path.basename;
    my $module      = $path.extension('').basename;

    my $model = Agrammon::Model.new(path => $module-path);
    $model.load($module);
    return $model.dump;
}
