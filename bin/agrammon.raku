#!/usr/bin/env raku

BEGIN my $root = $*PROGRAM.resolve.parent(2);
use lib "$root/lib".Str;
use lib:from<Perl5> "$root/Inline/perl5";

use Agrammon::UI::CommandLine;
