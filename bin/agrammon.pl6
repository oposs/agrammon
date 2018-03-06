#!/usr/bin/env perl6

use Agrammon::Model;

my %*SUB-MAIN-OPTS =
  :named-anywhere,    # allow named variables at any location 
;

subset ExistingFile of Str where { .IO.e or note("No such file $_") && exit 1 }

#| Run the model
multi sub MAIN('web', ExistingFile $filename) {
    say "Will start web service; NYI";
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
        Extra info here
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
