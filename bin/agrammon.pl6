#!/usr/bin/env perl6

use Agrammon::UI::CommandLine;

my %*SUB-MAIN-OPTS =
  :named-anywhere,    # allow named variables at any location 
;

subset ExistingFile of Str where { .IO.e or note("No such file $_") && exit 1 }
subset SupportedLanguage of Str where { $_ ~~ /de|en|fr/ or note("ERROR: --language=[de|en|fr]") && exit 1 };

#| Start the web interface
multi sub MAIN('web', ExistingFile $cfg-filename, ExistingFile $model-filename, Str $tech-file?) {
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
