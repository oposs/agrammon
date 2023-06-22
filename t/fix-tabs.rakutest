use v6;
use Agrammon::TabFixer;
use Test;

plan 6;

{
    my @warnings;
    CONTROL {
        when CX::Warn {
            push @warnings, .message;
        }
    }
    is fix-tabs("no problemo   \nno tabs here!\n"),
        "no problemo   \nno tabs here!\n",
        'No tabs in input means no changes';
    is @warnings.elems, 0, 'No warnings when no tabs to fix';
}

{
    my @warnings;
    CONTROL {
        when CX::Warn {
            push @warnings, .message;
            .resume;
        }
    }
    is fix-tabs("a tab\ton first\nsecond ok\n\t at start of third\n"),
        "a tab    on first\nsecond ok\n     at start of third\n",
        'Tabs in input changed to four spaces';
    is @warnings.elems, 2, 'A warning for each of the tabs fixed';
    like @warnings[0], /'line 1'/, 'Line number of tab reported in warning (1)';
    like @warnings[1], /'line 3'/, 'Line number of tab reported in warning (2)';
}
