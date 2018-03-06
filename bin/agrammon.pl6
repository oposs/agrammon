#!/usr/bin/env perl6

use Agrammon::Model;

my %*SUB-MAIN-OPTS =
  :named-anywhere,    # allow named variables at any location 
;

#| Run the model
multi sub MAIN('web', $filename) {
    say "Will start web service; NYI";
}

#| Run the model
multi sub MAIN('run', $filename) {
    say "Will run the model; NYI";
}

#| Dump model
multi sub MAIN('dump', $filename) {
    say chomp dump $filename.IO;
}

sub dump (IO::Path $path) {
    die "ERROR: Dump expects a .nhd file" unless $path.extension eq 'nhd';

    my $module-path = $path.parent;
    my $module-file = $path.basename;
    my $module      = $module-file.IO.extension: '';

    my $model = Agrammon::Model.new(path => $module-path);
    $model.load($module);
    return $model.dump;
}
