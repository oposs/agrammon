use v6;
use Agrammon::Config;
use Agrammon::Webservice;

use Test;
plan 9;

my $cfg-file = "t/test-data/agrammon.cfg.yaml";
my $username = 'fritz.zaucker@oetiker.ch';

my ($ws, $user);
subtest "Setup" => {
    my $cfg = Agrammon::Config.new;
    ok $cfg.load($cfg-file), "Load config from file $cfg-file";
    $user = Agrammon::User.new;
    ok $user.load($username), "Load user $username";
    ok $ws = Agrammon::Webservice.new(
        cfg => $cfg,
        user => $user),               "Created Webservice object";
    is $ws.user.username, $username,  "Webservice has username=username";
}

subtest "get-cfg()" => {
    isa-ok $ws.get-cfg, "Agrammon::Config", "Got Agrammon::Config object";
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

todo "Not implemented yet", 6;
subtest "load-dataset()" => {
    flunk("Not implemented");
}

subtest "create-dataset()" => {
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
