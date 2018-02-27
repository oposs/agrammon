use v6;
use Test::NoTabs;

my @dirs;
@dirs.push($*PROGRAM.parent.parent.path);
all-perl-files-ok(@dirs);
