use v6;
use Agrammon::Config;
use Agrammon::Web::Service;

use DB::Pg;
use Test;
plan 9;

my $cfg-file = "t/test-data/agrammon.cfg.yaml";
my $username = 'fritz.zaucker@oetiker.ch';

if (%*ENV<TRAVIS>) {
    skip-rest('Not set up for Travis yet');
    exit;
}

my $*AGRAMMON-DB-CONNECTION;
my ($ws, $user);
subtest "Setup" => {
    my $cfg = Agrammon::Config.new;
    ok $cfg.load($cfg-file), "Load config from file $cfg-file";
    ok $*AGRAMMON-DB-CONNECTION = DB::Pg.new(conninfo => $cfg.db-conninfo), 'Create DB::Pg object';
    $user = Agrammon::DB::User.new;
    ok $user.load($username), "Load user $username";
    ok $ws = Agrammon::Web::Service.new(
        cfg => $cfg,
        user => $user),               "Created Web::Service object";
    is $ws.user.username, $username,  "Web::Service has username=username";
}

subtest "get-cfg()" => {
    my %cfg-expected = (
        guiVariant => "Single",
        modelVariant => "SHL",
        title => {de => "AGRAMMON 4.0 Einzelbetriebsmodell",
                  en => "AGRAMMON 4.0 Single Farm Model",
                  fr => "AGRAMMON 4.0 modèle Exploitation individuelle"
                 },
        variant => "SHL",
        version => "4.0 - #REV#"
    );
    is-deeply my $cfg = $ws.get-cfg, %cfg-expected, "Config as expected";
}

subtest "get-datasets()" => {
    my $model-version = 'SingleSHL';
    ok my $datasets = $ws.get-datasets($model-version), "Get $model-version datasets";
    isa-ok $datasets, 'Agrammon::DB::Datasets', 'Got Agrammon::DB::Datasets object';
    is $datasets.user.username, $username, "Datasets has username=$username";
    my @collection = $datasets.collection;
    isa-ok @collection[0], 'Agrammon::DB::Dataset', 'First dataset is Agrammon::DB::Dataset';
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
