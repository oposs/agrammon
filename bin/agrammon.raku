#!/usr/bin/env raku
# unbuffered output
$*OUT.out-buffer = False;
$*ERR.out-buffer = False;
use lib $*PROGRAM.resolve.parent(2) ~ '/lib';
use lib:from<Perl5> $*PROGRAM.resolve.parent(2) ~ '/Inline/perl5';
use Agrammon::UI::CommandLine;
