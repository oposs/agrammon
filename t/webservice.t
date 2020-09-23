use v6;
use Agrammon::Config;
use Agrammon::Model;
use Agrammon::UI::Web;
use Agrammon::Web::Service;
use Agrammon::Web::SessionUser;
use DB::Pg;
use Test;

# FIX ME: use separate test database

plan 29;

if %*ENV<AGRAMMON_UNIT_TEST> {
    skip-rest 'Not a unit test';
    exit;
}

my $cfg-file = %*ENV<AGRAMMON_CFG> // "t/test-data/agrammon.cfg.yaml";
my $username = 'fritz.zaucker@oetiker.ch';

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

transactionally {

    subtest "create-dataset" => {
        ok my $dataset-name = $ws.create-dataset($user, "MyTestDataset"), "Create dataset";
        is $dataset-name, "MyTestDataset", "Dataset has correct name";
    }

    subtest "get-datasets()" => {
        my $model-version = 'SingleSHL';
        ok my $datasets = $ws.get-datasets($user, $model-version), "Get $model-version datasets";
        isa-ok $datasets, 'Array', 'Got datasets Array';

        ok $datasets.elems >= 8, "Found right number of datasets";
        isa-ok my $dataset = $datasets[0], 'List', 'Got dataset List';
        is $dataset[0], 'MyTestDataset', 'First dataset has name MyTestDataset';
        is $dataset[7], 'SingleSHL', 'First dataset has model variant SingleSHL';

        my $found;
        for @$datasets -> $dataset {
            $found = $dataset[0] eq 'Agrammon6Testing';
            last if $found;
        }
        ok $found, 'Found dataset Agrammon6Testing';
    }

    subtest "rename-dataset" => {
        lives-ok { $ws.rename-dataset($user, 'MyTestDataset', 'MyNewTestDataset') }, "Rename dataset";
    }

    subtest "submit-dataset" => {
        ok $ws.submit-dataset($user, 'MyTestDataset', 'foo@bar.ch'), "Submit dataset";
    }

    my $newUser;
    subtest "create-account" => {
        my $userData = \(
            :username('foo@bar.ch'),
            :firstname('Erika'),
            :lastname('Mustermann'),
            :password('myPass'),
            :organisation('Org'),
        );
        ok $newUser = $ws.create-account($user, $userData), "Create new account";
        is $newUser.username, 'foo@bar.ch', "User has expected username";
    }

    subtest "change-password" => {
        ok $ws.change-password($user, "test12", "test34"), 'Password update sucessful';
        nok $ws.change-password($user, "test12", "test34"), 'Password update failed';
    }

    subtest "create-tag" => {
        ok my $tag = $ws.create-tag($user, "00MyTestTag"), "Create tag";
        is $tag.name, "00MyTestTag", "Tag has correct name";
    }

    subtest "rename-tag" => {
        ok my $newTag = $ws.rename-tag($user, '00MyTestTag', '00MyNewTestTag'), "Rename tag";
        is $newTag.name, '00MyNewTestTag', 'Tag has expected name';
    }

     subtest "get-tags()" => {
        ok my $tags = $ws.get-tags($user), "Get tags";
        # isa-ok $tags, 'Array', 'Got tags Array';
        ok $tags.elems >= 12,  "Found 12+ tags";
        # isa-ok my $tag = $tags[0], 'List', 'Got tag List';
        is $tags[0], '00MyNewTestTag', 'First tag has name 00MyNewTestTag';
        # dd $tags;
    }


    subtest "set-tag" => {
        ok my $dataset = $ws.set-tag($user, 'MyNewTestDataset', '00MyNewTestTag'), "Set tag";
    }

    subtest "remove-tag" => {
        ok my $dataset = $ws.remove-tag($user, 'MyNewTestDataset', '00MyNewTestTag'), "Remove tag";
    }

    subtest "delete-tag" => {
        ok my $tag = $ws.delete-tag($user, 'MyNewTestTag'), "Delete tag";
    }

    subtest "store-dataset-comment" => {
        ok my $comment = $ws.store-dataset-comment($user, 'MyNewTestDataset', 'MyComment'), "Store dataset comment";
    }

    subtest "store-input-comment" => {
        my $dataset-name = 'MyNewTestDataset';
        my $var-name     = 'Application::Slurry::Csoft::appl_evening';
        my $comment      = 'MyComment';
        ok my $newComment = $ws.store-input-comment($user, $dataset-name, $var-name, $comment), "Store input comment";
    }

    subtest "load-dataset" => {
        my @data = $ws.load-dataset($user, 'Agrammon6Testing');
    };

    subtest "rename-instance" => {
        ok my $ret = $ws.rename-instance(
            $user, 'TestSingle',
            'Stall Milchkühe', 'MKühe',
            'Livestock::DairyCow[]'
        ), "Rename instance";
    }

    subtest "order-instances" => {
        my @instances = 'InstA', 'InstB';
        ok $ws.order-instances($user, 'Agrammon6Testing', @instances), "Order instances";
    };

    subtest "store-data" => {
        my %data = %(
            :dataset_name('MyNewTestDataset'),
            :data_var('PlantProduction::AgriculturalArea::agricultural_area'),
            :data_val(42)
        );
        ok $ws.store-data($user, %data), "Simple input stored";

        %data = %(
            :dataset_name('MyNewTestDataset'),
            :data_var('Livestock::DairyCow[MK]::Excretion::dairy_cows'),
            :data_val(42)
        );
        ok $ws.store-data($user, %data), "Instance input stored";
    }

    # TODO: replace with deletion of real data and check for deleted rows
    subtest "delete-data" => {
        my %data = %(
            :dataset_name('MyNewTestDataset'),
            :pattern('PlantProduction::AgriculturalArea::agricultural_area'), # var name
        );
        lives-ok { $ws.delete-data($user, %data) }, "Simple input deleted";
        todo "Needs deletion of existing data", 1;
        ok $ws.delete-data($user, %data), "Simple input deleted";

        %data = %(
            :dataset_name('MyNewTestDataset'),
            :pattern('Livestock::DairyCow[MK]::Excretion::dairy_cows'), # var name
            :instance('MK'),
        );
        lives-ok { $ws.delete-data($user, %data) }, "Instance input deleted";
        todo "Needs deletion of existing data", 1;
        ok $ws.delete-data($user, %data), "Instance input deleted";
    }

    subtest "reset-password" => {
        ok  $ws.reset-password($user, 'foo@bar.ch', "test12", "hash"), 'Password reset sucessful';
        nok $ws.reset-password($user, 'foo@bar.ch', "test34", ""),     'Password reset without key fails';
    }

    subtest "load-branch-data" => sub {
        return $ws.load-branch-data($user, 'MyTestDataset');
    }

    subtest "store-branch-data" => sub {
        return $ws.store-branch-data($user, 'MyTestDataset', %( :x(1), :y(2) ) );
    }

    subtest "delete-datasets" => {
        is $ws.delete-datasets($user, @('MyNewTestDataset')), 1, 'One dataset deleted';
    }

}

transactionally {

    @($ws.get-datasets($user, 'SingleSHL')).map: *[0].note;

    throws-like { $ws.rename-dataset($user, 'TestSingle', 'Agrammon6Testing') },
        X::Agrammon::DB::Dataset::AlreadyExists,
        "Rename dataset fails for existing new dataset name";

    @($ws.get-datasets($user, 'SingleSHL')).map: *[0].note;

}

transactionally {

    throws-like { $ws.rename-dataset($user, 'TestSingle', 'TestSingle') },
        X::Agrammon::DB::Dataset::RenameFailed,
        "Rename dataset fails if old and new name are identical";

}

transactionally {

    throws-like { $ws.rename-dataset($user, 'NoDataset', 'NewDataset') },
        X::Agrammon::DB::Dataset::RenameFailed,
        "Rename dataset fails if old dataset name doesn't exist";

}

subtest "Get model data" => {

    my $path = $*PROGRAM.parent.add('test-data/Models/hr-inclNOx/');
    my $top = 'End';
    ok my $model = Agrammon::Model.new(:$path), "Load model";
    lives-ok { $model.load($top) }, "Load module from $top";

    ok my $ui-web = Agrammon::UI::Web.new(:$model);

    my %input-hash = $ui-web.get-input-variables;
    %input-hash<dataset> = 'TEST';
    is-deeply %input-hash.keys.sort, qw|dataset graphs inputs reports| , "Input hash has expected keys";

    subtest "get-input-variables" => {
        with %input-hash<inputs> -> @module-inputs {
            for @module-inputs -> $input {
                my $var    = $input<variable>;
                next unless $var ~~ /'::dairy_cows'/;
                is-deeply $input.keys.sort, qw|branch defaults enum gui help labels models options optionsLang order type units validator variable|,
                          "$var has expected keys";
                if $var ~~ /'::dairy_cows'/ {
                    # dd $input;
                    subtest "$var" => {
# TODO: needs fixing
#                        is $input<branch>, 'true', 'branch is true';
                        is-deeply $input<defaults>, %( calc => Any, gui => Any);
                        is-deeply $input<validator>, %( args => ["0"], name => "ge"), "validator as expected";
                    }
                }
            }
        }
    };

# TODO: fix
    todo "Not implemented yet", 1;
    subtest "get-output-variables" => {


flunk "get-output-variables";
#        my %outputs = $model.run(:$input).get-outputs-hash();
#        dd %outputs;

#         with %input-hash<outputs> -> @module-inputs {
#             for @module-inputs -> $input {
#                 my $var    = $input<variable>;
#                 is-deeply $input.keys.sort, qw|branch defaults enum gui help labels models options optionsLang order type units validator variable|,
#                           "$var has expected keys";
#                 if $var ~~ /'::dairy_cows'/ {
#                     dd $input;
#                     subtest "$var" => {
# # TODO: needs fixing
# #                        is $input<branch>, 'true', 'branch is true';
#                         is-deeply $input<defaults>, %( calc => Any, gui => Any);
#                         is-deeply $input<validator>, %( args => ["0"], name => "ge"), "validator as expected";
#                     }
#                 }
#             }
#         }
    }


    subtest "graphs and reports" => {
        my $graphs = %input-hash<graphs>;

        my %graph = $graphs[0];
        is-deeply %graph.keys.sort, qw|_order data name selector type|, "First graph has expected keys";
        is %graph<type>, 'bar', "Graph has correct type";

        my $reports = %input-hash<reports>;
        my %report = $reports[0];
        is-deeply %report.keys.sort, qw|_order data name selector type|, "First report has expected keys";
        is %report<type>, 'report', "Report has correct type";

    }

}


done-testing;

sub transactionally(&test) {
    my $*AGRAMMON-DB-HANDLE = my $db = $*AGRAMMON-DB-CONNECTION.db;
    $db.begin;
    test($db);
    $db.finish;
}
