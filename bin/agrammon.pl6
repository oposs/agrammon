#!/usr/bin/env perl6

use Cro::HTTP::Log::File;
use Cro::HTTP::Server;

use Agrammon::Config;
use Agrammon::Model;
use Agrammon::Web::Routes;

my %*SUB-MAIN-OPTS =
  :named-anywhere,    # allow named variables at any location 
;

subset ExistingFile of Str where { .IO.e or note("No such file $_") && exit 1 }

#| Start the web interface
multi sub MAIN('web', ExistingFile $filename) {
    my $username = 'fritz.zaucker@oetiker.ch';
    my $cfg-file = 't/test-data/agrammon.cfg.yaml';
    my $cfg = Agrammon::Config.new;
    $cfg.load($cfg-file);
    my $user = Agrammon::DB::User.new;
    $user.load($username, $cfg);
    my $ws = Agrammon::Web::Service.new(
        cfg => $cfg,
        user => $user);
    say "Starting web service ...";
    my $host = %*ENV<AGRAMMON_HOST> || '0.0.0.0';
    my $port = %*ENV<AGRAMMON_PORT> || 20000;
    my Cro::Service $http = Cro::HTTP::Server.new(
        host => $host,
        port => $port,
        application => routes($ws),
        after => [
                  Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
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
multi sub MAIN('run', ExistingFile $filename) {
    say "Will run the model; NYI";
}

#| Dump model
multi sub MAIN('dump', ExistingFile $filename) {
    say chomp dump $filename.IO;
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

sub dump (IO::Path $path) {
    die "ERROR: Dump expects a .nhd file" unless $path.extension eq 'nhd';

    my $module-path = $path.parent;
    my $module-file = $path.basename;
    my $module      = $path.extension('').basename;

    my $model = Agrammon::Model.new(path => $module-path);
    $model.load($module);
    return $model.dump;
}
