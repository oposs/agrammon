use v6;
#use Agrammon::Config;
use Agrammon::Webservice;

#use Cro::HTTP::Client;
use Test;
plan 9;

my %config-expected = (
    General => {
        debugLevel  => 0,
        log_file    => "/tmp/agrammon.log",
        log_level   => "warn",
        mojo_secret => "MyCookieSecret",
    },
    Database => {
        dbi_dsn  => "dbi:Pg:dbname=agrammon_dev;host=erika.oetiker.ch",
        dbi_user => "agrammon",
        dbi_pass => "agrammonPassword",
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

my ($ws, $user);
my $username = 'fritz.zaucker@oetiker.ch';

subtest "Webservice" => {
    $user = Agrammon::User.new;
    $user.load($username);
    ok $ws = Agrammon::Webservice.new(user => $user), "Created Webservice object";
    is $ws.user.username, $username,                  "Webservice has username=username";
}

subtest "get-datasets()" => {
    my $model-version = 'SingleSHL';
    ok my $datasets = $ws.get-datasets($model-version), "Get $model-version datasets";
    isa-ok $datasets, 'Agrammon::Datasets', 'Got Agrammon::Datasets object';
    is $datasets.user.username, $username, "Datasets has username=$username";
    my @collection = $datasets.collection;
    isa-ok @collection[0], 'Agrammon::Dataset', 'First dataset is Agrammon::Dataset';
    is @collection[0].name, 'TestSingle', 'First dataset has name TestSingle';
}

todo "Not implemented yet", 7;
subtest "load-dataset()" => {
    flunk("Not implemented");
}

subtest "create-dataset()" => {
    flunk("Not implemented");
}

subtest "get-cfg()" => {
    flunk("Not implemented");
}

subtest "get-tags()" => {
    flunk("Not implemented");
}

subtest "get-input-variables()" => {
    flunk("Not implemented");
}

subtest "get-output-variables()" => {
    flunk("Not implemented");
}

subtest "create-account()" => {
    flunk("Not implemented");
}


done-testing;
