use v6;
use Agrammon::Config;

use Test;
plan 3;

my %config-expected = (
    General => {
        debugLevel  => 0,
        log_file    => "/tmp/agrammon.log",
        log_level   => "warn",
        mojo_secret => "MyCookieSecret",
    },
    Database => {
        name     => 'agrammon_dev',
        host     => 'erika.oetiker.ch',
        user     => 'agrammon',
        password => "agrammon@work",
    },
    GUI => {
        variant => "Single",
        title   => {
            de => "AGRAMMON 4.0 Einzelbetriebsmodell",
            en => "AGRAMMON 4.0 Single Farm Model",
            fr => "AGRAMMON 4.0 modele Exploitation individuelle" ,
        },
    },
    Model => {
        debugLevel => 0,
        home       => "/home/zaucker/Agrammon",
        path       => "Models/branches/hr-limit-2010_details",
        root       => "End.nhd",
        technical  => "technical.cfg",
        variant    => "SHL",
        version    => "4.0 - #REV#",
    },
);

my $file = "t/test-data/agrammon.cfg.yaml";

ok my $cfg = Agrammon::Config.new, 'Create Agrammon Config';
ok $cfg.load($file), "Load config from file $file";
is-deeply %(
    General  => $cfg.general,
    Database => $cfg.database,
    GUI      => $cfg.gui,
    Model    => $cfg.model), %config-expected, 'Config as expected';

done-testing;
