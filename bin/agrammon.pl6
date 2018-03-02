#!/usr/bin/env perl6

use Agrammon::Model;

my %*SUB-MAIN-OPTS =
  :named-anywhere,    # allow named variables at any location 
;

sub MAIN (
    Str $command   = 'help',
    Str $filename? = %*ENV{'AGRAMMON_MODEL_START'} // '';
) {

    {
        say "No filename";
        USAGE();
        exit 1;
    } unless $filename;

    given $command {
        when 'run'  { say 'Will run the model; not yet implemented' }
        when 'web'  { say 'Will start web service; not yet implemented' }
        when 'dump' { dump $filename.IO; }
        default { USAGE(); }
    }
}

sub dump (IO::Path $path) {
    die "ERROR: Dump expects a .nhd file" unless $path.extension eq 'nhd';

    my $module-path = $path.parent;
    my $module-file = $path.basename;
    my $module      = $module-file.IO.extension: '';

    my $model = Agrammon::Model.new(path => $module-path);
    $model.load($module);
    $model.dump;
}

sub USAGE(){
    # "empty" lines in the here doc must have leading spaces!
    print q:c:to/EOH/; 
        Usage: {$*PROGRAM-NAME} [command] [filename]
               
               command  [help | web | dump | run]
               filename Start at this file. 
               
               filename defaults to \q{%*ENV{AGRAMMON_MODEL_START}} if not specified.
        EOH
}
