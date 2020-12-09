use v6;
use Agrammon::Config;

use Test;
plan 9;

my %config-expected = (
    General => {
        debugLevel  => 0,
        log_file    => "/tmp/agrammon.log",
        log_level   => "warn",
        tempDir     =>  "agrammon",
        pdflatex    => "/usr/bin/lualatex"
    },
    Database => {
        name     => 'agrammon_test',
        host     => 'localhost',
        user     => 'agrammon',
        password => "agrammonATwork",
    },
    GUI => {
        variant => "Single",
        title   => {
            de => "AGRAMMON 6.0 Einzelbetriebsmodell",
            en => "AGRAMMON 6.0 Single Farm Model",
            fr => "AGRAMMON 6.0 modèle Exploitation individuelle" ,
        },
    },
    Model => {
        debugLevel => 0,
        home       => "/home/zaucker/Agrammon",
        path       => "Models/branches/hr-inclNOxExtendedWithFilters",
        root       => "End.nhd",
        technical  => "technical.cfg",
        variant    => "SHL",
        version    => "6.0 - #REV#",
    },
);

my $file = "t/test-data/agrammon.cfg.yaml";

ok my $cfg = Agrammon::Config.new, 'Create Agrammon Config';
ok $cfg.load($file), "Load config from file $file";

is-deeply $cfg.general,     %config-expected<General>,            'Config.general as expected';
is-deeply $cfg.gui,         %config-expected<GUI>,                'Config.gui as expected';
is-deeply $cfg.model,       %config-expected<Model>,              'Config.model as expected';
is $cfg.database<name>,     %config-expected<Database><name>,     'Config.database.name as expected';
is $cfg.database<user>,     %config-expected<Database><user>,     'Config.database.user as expected';
is $cfg.database<password>, %config-expected<Database><password>, 'Config.database.user as expected';
# hostname might be different in dev, ci, and prod
ok $cfg.database<host>,     'Config.database.host exists';

done-testing;
