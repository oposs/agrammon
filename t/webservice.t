use v6;
use Agrammon::DB::User;
use Agrammon::Config;
use Agrammon::Model;
use Agrammon::Performance;
use Agrammon::TechnicalParser;
use Agrammon::UI::Web;
use Agrammon::Web::Service;
use Agrammon::Web::SessionUser;
use DB::Pg;
use Test;

use lib 't/lib';
use AgrammonTest;

# FIX ME: use separate test database

plan 37;

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

    my $path = $*PROGRAM.parent.add('test-data/Models/hr-inclNOxExtendedWithFilters/');
    my $top = 'End';
    ok my $model = Agrammon::Model.new(:$path), "Load model";
    lives-ok { $model.load($top) }, "Load module from $top";

    my $tech-input = $path.add('technical.cfg');
    ok my %technical-parameters = timed "Load parameters from $tech-input", {
        my $params = parse-technical($tech-input.IO.slurp);
        %($params.technical.map(-> %module {
            %module.keys[0] => %(%module.values[0].map({ .name => .value }))
        }));
    };
    ok $ws = Agrammon::Web::Service.new(:$cfg, :$model, :%technical-parameters), "Create Web::Service object";
}

subtest "get-cfg()" => {
    my %cfg-expected = (
        guiVariant => "Single",
        modelVariant => "SHL",
        submission => Any,
        title => {de => "AGRAMMON 6.0 Einzelbetriebsmodell",
                  en => "AGRAMMON 6.0 Single Farm Model",
                  fr => "AGRAMMON 6.0 modèle Exploitation individuelle"
                 },
        variant => "SHL",
        version => "6.0 - #REV#"
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
        isa-ok $datasets[0], 'List', 'Got dataset List';

        my $found;
        my $dataset;
        for @$datasets -> $ds {
            if $found = $ds[0] eq 'MyTestDataset' {
                $dataset = $ds;
                last;
            }
        }
        ok $found, 'Found dataset MyTestDataset';
        is $dataset[7], 'SingleSHL', 'First dataset has model variant SingleSHL';
    }

    subtest "clone-dataset" => {
        my $new-username = 'fritz.zaucker@oetiker.ch';
        my $old-dataset = 'Agrammon6Testing';
        my $new-dataset = 'Agrammon6Testing Kopie';
        lives-ok { $ws.clone-dataset($user, $new-username, $old-dataset, $new-dataset) }, "Clone dataset";
    }

    subtest "rename-dataset" => {
        lives-ok { $ws.rename-dataset($user, 'MyTestDataset', 'MyNewTestDataset') }, "Rename dataset";
    }

    skip "submit-dataset not ready yet for testing", 1;
    #subtest "submit-dataset" => {
    #    my %params;
    #    ok $ws.submit-dataset($user, %params), "Submit dataset";
    #}

    my $newUser;
    subtest "create-account" => {
        ok $username = $ws.create-account(
            $user,
            'foo@bar.com', 'myPassword', 'myKey',
            'Erika', 'Mustermann', 'MyOrg', 'user'
        ), "Create new user account with all data";
        is $username, 'foo@bar.com', "User has expected username";

        ok $username = $ws.create-account(
            $user,
            'foo2@bar.com', 'myPassword', Any,
            Any, Any, Any, 'user'
        ), "Create new user account with only required data";
        is $username, 'foo2@bar.com', "User has expected username";

        ok $username = $ws.create-account(
            $user,
            'foo3@bar.com', 'myPassword', Any,
            Any, Any, Any, Any
        ), "Create new user account with only required data with default role";
        is $username, 'foo3@bar.com', "User has expected username";
    }

    subtest "change-password" => {
        lives-ok    { $ws.change-password($user, "test12", "test34") }, 'Password update sucessful';
        throws-like { $ws.change-password($user, "test12", "test34") },
            X::Agrammon::DB::User::InvalidPassword, 'Password invalid';
        throws-like { $ws.change-password($user, "test34", "test34") },
            X::Agrammon::DB::User::PasswordsIdentical, 'Passwords identical';
    }

    subtest "reset-password" => {
        lives-ok  { $ws.reset-password($user, 'foo@bar.com', "test12", "hash") }, 'Password reset sucessful';
        throws-like { $ws.reset-password($user, 'foo@bar.com', "test34", "") },
            X::Agrammon::DB::User::PasswordResetFailed, 'Passwords reset without key fails';
    }

    subtest "create-tag" => {
        lives-ok { $ws.create-tag($user, "00MyTestTag") }, "Create tag";
    }

    subtest "rename-tag" => {
        lives-ok { $ws.rename-tag($user, '00MyTestTag', '00MyNewTestTag') }, "Rename tag";
    }

    subtest "get-tags()" => {
        ok my $tags = $ws.get-tags($user), "Get tags";
        ok $tags.elems >= 12, "Found 12+ tags";
        is $tags[0], '00MyNewTestTag', 'First tag has name 00MyNewTestTag';
    }

    subtest "set-tag" => {
        lives-ok { $ws.set-tag($user, ['MyNewTestDataset'], '00MyNewTestTag') }, "Set tag";
    }

    subtest "remove-tag" => {
        lives-ok { $ws.remove-tag($user, ['MyNewTestDataset'], '00MyNewTestTag') }, "Remove tag";
    }

    subtest "delete-tag" => {
        lives-ok { $ws.create-tag($user, "07TestTag") }, "Create tag";
        lives-ok { $ws.delete-tag($user, '07TestTag') }, "Delete tag";
    }

    subtest "store-dataset-comment" => {
        ok my $comment = $ws.store-dataset-comment($user, 'MyNewTestDataset', 'MyComment'), "Store dataset comment";
    }

    subtest "store-input-comment" => {
        my $dataset = 'MyNewTestDataset';
        my $variable = 'Application::Slurry::Csoft::appl_evening';
        my $comment = 'MyComment';
        lives-ok { $ws.store-input-comment($user, $dataset, $variable, $comment) }, "Store input comment";
    }

    subtest "load-dataset" => {
        lives-ok { $ws.load-dataset($user, 'Agrammon6Testing') }, "Load Agrammon6Testing";
    };

    subtest "rename-instance" => {
        lives-ok {
            $ws.rename-instance(
                $user, 'TestSingle',
                'Stall Milchkühe', 'MKühe',
                'Livestock::DairyCow[]'
            )
        }, "Rename instance";
    }

    subtest "order-instances" => {
        lives-ok { $ws.order-instances(
            $user, 'Agrammon6Testing',
            ('Livestock::OtherCattle[Test1]', 'Livestock::OtherCattle[Test]',))
        }, "Order instances";
    };

    subtest "store-data" => {
        my $dataset = 'MyNewTestDataset';
        my $variable = 'PlantProduction::AgriculturalArea::agricultural_area';
        my $value = 42;
        my $row   = 1;
        lives-ok { $ws.store-data($user,  $dataset, $variable, $value) }, "Simple input stored";

        $variable = 'Livestock::DairyCow[MK]::Excretion::dairy_cows';
        my @branches;
        my @options;
        lives-ok { $ws.store-data($user, $dataset, $variable, $value, @branches, @options, $row) }, "Instance input stored";

        for %{ "Livestock::Poultry[Branched]::Housing::Type::housing_type" => 'deep_pit',
               "Livestock::Poultry[Branched]::Housing::Type::manure_removal_interval" => 'once_a_day'
        }.kv -> $variable, $value {
           lives-ok { $ws.store-data($user, $dataset, $variable, $value, @branches, @options, $row++) }, "Instance input stored";
       }
    }

    subtest "delete-instance" => {
        lives-ok { $ws.delete-instance(
            $user,
            'MyNewTestDataset',
            'Livestock::DairyCow[]',
            'MK'
        ) }, "Instance deleted";
    }

    subtest "store and load branch data" => sub {
        my @vars = (
            "Livestock::Poultry[]::Housing::Type::housing_type",
            "Livestock::Poultry[]::Housing::Type::manure_removal_interval",
        );
        my $instance = 'Branched';
        lives-ok { $ws.store-branch-data(
            $user, 'MyNewTestDataset', %(
                :@vars,
                :$instance,
                :options(
                    ${"Livestock::Poultry[]::Housing::Type::housing_type" => $[
                        "manure belt with manure belt drying system",
                        "manure belt without manure belt drying system",
                        "deep pit", "deep litter"
                    ],
                    "Livestock::Poultry[]::Housing::Type::manure_removal_interval" => $[
                        "less than twice a month",
                        "twice a month",
                        "3 to 4 times a month",
                        "more than 4 times a month",
                        "once a day",
                        "no manure belt"
                    ]}
                ),
                :data($[
                    ["0", "5", "0", "0", "0", "0"],
                    ["0", "0", "10", "7", "0", "0"],
                    ["13", "20", "0", "0", "0", "22"],
                    ["0", "15", "0", "8", "0", "0"]
                ])
            )
        )}, "Store branch data";

        lives-ok {  $ws.load-branch-data(
            $user, 'MyNewTestDataset', %(
                :vars(
                    $[
                        "Livestock::Poultry[]::Housing::Type::housing_type",
                        "Livestock::Poultry[]::Housing::Type::manure_removal_interval"
                    ]
                ),
                :$instance
            )
        )}, "Load branch data";
    }

    subtest "delete-datasets" => {
        is $ws.delete-datasets($user, @('MyNewTestDataset')), 1, 'One dataset deleted';
    }

}

transactionally {
    throws-like { $ws.rename-dataset($user, 'TestSingle', 'Agrammon6Testing') },
        X::Agrammon::DB::Dataset::AlreadyExists,
        "Rename dataset fails for existing new dataset name";
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

transactionally {
    $ws.create-tag($user, "01MyTestTag");
    $ws.create-tag($user, "02MyTestTag");
    throws-like { $ws.rename-tag($user, '01MyTestTag', '02MyTestTag') },
        X::Agrammon::DB::Tag::AlreadyExists,
        "Rename tag fails for existing new tag name";
}

transactionally {
    $ws.create-tag($user, "01MyTestTag");
    throws-like { $ws.rename-tag($user, '01MyTestTag', '01MyTestTag') },
        X::Agrammon::DB::Tag::RenameFailed,
        "Rename tag fails if old and new name are identical";
}

transactionally {
    throws-like { $ws.rename-tag($user, '03MyTestTag', '04MyTestTag') },
        X::Agrammon::DB::Tag::RenameFailed,
        "Rename tag fails if old tag name doesn't exist";
}

transactionally {
    throws-like { $ws.delete-tag($user, 'NoTag') },
        X::Agrammon::DB::Tag::DeleteFailed,
        "Delete tag fails if tag name doesn't exist";
}

transactionally {
    throws-like {
        $ws.create-account(
            $user,
            '', 'myPassword', Any,
            Any, Any, Any
        ) },
        X::Agrammon::DB::User::NoUsername,
        "User needs none-empty username/email";
}

transactionally {
    $ws.create-account(
        $user,
        'foo2@bar.com', 'myPassword', Any,
        Any, Any, Any
    );
    throws-like {
        $ws.create-account(
            $user,
            'foo2@bar.com', 'myPassword', Any,
            Any, Any, Any
        ) },
        X::Agrammon::DB::User::Exists,
        "User already exists";
}

transactionally {
    throws-like {
        $ws.create-account(
            $user,
            'foo3@bar.ch', 'myPassword', Any,
            Any, Any, Any, 'NoRole'
        ) },
        X::Agrammon::DB::User::UnknownRole,
        "User needs valid role";
}

subtest "Get model data" => {
    my $dataset-name = 'TestSingle';
    my $input-hash;

    subtest "Get input variables" => {
        ok $input-hash = $ws.get-input-variables, "Get inputs";
        is-deeply $input-hash.keys.sort, qw|graphs inputs reports| , "Input hash has expected keys";

        with $input-hash<inputs> -> @module-inputs {
            for @module-inputs -> $input {
                my $var    = $input<variable>;
                next unless $var ~~ /'::dairy_cows'/;
                is-deeply $input.keys.sort, qw|branch defaults enum gui help labels models options optionsLang order type units validator variable|,
                          "$var has expected keys";
                subtest "$var" => {
                    is $input<branch>, 'false', 'branch is false';
                    is-deeply $input<defaults>, %( calc => Any, gui => Any), "defaults as expected";
                    is-deeply $input<validator>, %( args => ["0"], name => "ge"), "validator as expected";
                }
            }
        }
    }

    subtest "get-output-variables" => {
        ok my $output-hash = $ws.get-output-variables($user, $dataset-name), "Get outputs";
        is-deeply $output-hash.keys.sort, qw|data log| , "Output hash has expected keys";
        is-deeply $output-hash<data>.[0].keys.sort, qw|filters format fullValue labels order print units value var| , "Output data value hash has expected keys";
        is-deeply $output-hash<data>.[0]<labels>.keys.sort, qw|de en fr sort| , "Output data value labels hash has expected keys";
    }

    subtest "graphs and reports" => {
# currently commented out in model
#        my $graphs = $input-hash<graphs>;
#        my %graph = $graphs[0];
#        is-deeply %graph.keys.sort, qw|data name order resultView selector submit type|, "First graph has expected keys";
#        is %graph<type>, 'bar', "Graph has correct type";

        my $reports = $input-hash<reports>;
        my %report = $reports[0];
        is-deeply %report.keys.sort, qw|data name order resultView selector submit type|, "First report has expected keys";
        is %report<type>, 'report', "Report has correct type";
    }

}

subtest "get-excel-export" => {
    my $dataset-name = 'TestSingle';
    my %params = %(
        :datasetName($dataset-name),
        :language('de'),
        :reportSelected(0),
    );
    ok my $workbook = $ws.get-excel-export($user, %params), "Create workbook";

    is $workbook.worksheets[0;0].name,  'Ergebnisse',            "Excel workbook has correct name";
    is $workbook.worksheets[1;0].name,  'Ergebnisse formatiert', "Excel workbook has correct name";
    is $workbook.worksheets[2;0].name,  'Eingaben',              "Excel workbook has correct name";
    is $workbook.worksheets[3;0].name,  'Eingaben formatiert',   "Excel workbook has correct name";

    # TODO: add real tests once implementation is complete
    my $cells = $workbook.worksheets[1].cells;
    is $cells[0;0].value,  $dataset-name, "A1 has correct value";
}

done-testing;
