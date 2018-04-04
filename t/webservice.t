use v6;
use Agrammon::Config;
use Agrammon::Model;
use Agrammon::Web::Service;
use Agrammon::Web::SessionUser;
use DB::Pg;
use Test;

plan 9;

if %*ENV<AGRAMMON_UNIT_TEST> {
    skip-rest 'Not a unit test';
    exit;
}

my $cfg-file = "t/test-data/agrammon.cfg.yaml";
my $username = 'fritz.zaucker@oetiker.ch';

if %*ENV<TRAVIS> {
    skip-rest('Not set up for Travis yet');
    exit;
}

my $*AGRAMMON-DB-CONNECTION;
my ($ws, $user);
subtest "Setup" => {
    my $cfg = Agrammon::Config.new;
    ok $cfg.load($cfg-file), "Load config from file $cfg-file";
    ok $*AGRAMMON-DB-CONNECTION = DB::Pg.new(conninfo => $cfg.db-conninfo), 'Create DB::Pg object';
    $user = Agrammon::Web::SessionUser.new(:$username);
    ok $user.load, "Load user $username";
    ok $ws = Agrammon::Web::Service.new(:$cfg), "Created Web::Service object";
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
    ok my $datasets = $ws.get-datasets($user, $model-version), "Get $model-version datasets";
    isa-ok $datasets, 'Array', 'Got datasets Array';
    isa-ok my $dataset = $datasets[0], 'List', 'Got dataset List';
    is $dataset[0], 'TestSingle', 'First dataset has name TestSingle';
    is $dataset[7], 'SingleSHL', 'First dataset has model variant SingleSHL';
}

subtest "get-input-variables()" => {

    my $path = $*PROGRAM.parent.add('test-data/Models/hr-inclNOx/');
#    my $top = 'PlantProduction';
    my $top = 'Total';
#    my $top = 'Livestock';
    my $model = Agrammon::Model.new(path => $path);
    lives-ok { $model.load($top) }, "Loaded $top";

    my %input-hash = $model.get-input-variables;
    %input-hash<dataset> = 'TEST';
    is-deeply %input-hash.keys.sort, qw|dataset graphs inputs reports| , "Input hash has expected keys";

    subtest "input variables" => {
        with %input-hash<inputs> -> @module-inputs {
            for @module-inputs -> @inputs {
                for @inputs -> $input {
                    my $var    = $input<variable>;
                    is-deeply $input.keys.sort, qw|branch defaults gui help labels models options optionsLang order type units validator variable|,
                        "$var has expected keys";
                    if $var ~~ /\:\:dairy_cows/ {
#                        dd $input;
                        subtest "$var" => {
                            is $input<branch>, 'true', 'branch is true';
                            is-deeply $input<defaults>, %( calc => Any, gui => Any);
                            is-deeply $input<validator>, %( args => ["0"], name => "ge"), "validator as expected";
                        }
                    }
                }
            }
        }
    };

    subtest "graphs and reports" => {
        my @graphs = %input-hash<graphs>;
#        dd @graphs;
        my %graph = @graphs[0];
        is-deeply %graph.keys.sort, qw|_order data name selector type|, "First graph has expected keys";
        is %graph<type>, 'bar', "Graph has correct type";

        my @reports = %input-hash<reports>;
        my %report = @reports[0];
        is-deeply %report.keys.sort, qw|_order data name selector type|, "First report has expected keys";
        is %report<type>, 'report', "Report has correct type";

    }
}

todo "Not implemented yet", 5;
subtest "load-dataset()" => {
    flunk("Not implemented");
}

subtest "create-dataset()" => {
    flunk("Not implemented");
}

subtest "get-tags()" => {
    flunk("Not implemented");
}

subtest "get-output-variables()" => {
    flunk("Not implemented");
}

subtest "create-account()" => {
    flunk("Not implemented");
}


done-testing;
