use v6;
use Agrammon::Config;
use Agrammon::DB::Dataset;
use Agrammon::DB::User;
use Agrammon::Web::SessionUser;
use DB::Pg;
use JSON::Fast;
use Test;

use lib 't/lib';
use AgrammonTest;

plan 12;

if %*ENV<AGRAMMON_UNIT_TEST> {
    skip-rest 'Not a unit test';
    exit;
}

my $*AGRAMMON-DB-CONNECTION;

subtest 'Connect to database' => {
    plan 2;
    my $conninfo;
    my $cfg-file;
    if %*ENV<DRONE_REPO> {
        $cfg-file = %*ENV<AGRAMMON_CFG> // "t/test-data/agrammon.drone.cfg.yaml";
    }
    else {
        $cfg-file = %*ENV<AGRAMMON_CFG> // "t/test-data/agrammon.cfg.yaml";
    }
    my $cfg = Agrammon::Config.new;
    ok $cfg.load($cfg-file), "Load config from file $cfg-file";
    $conninfo = $cfg.db-conninfo;
    ok $*AGRAMMON-DB-CONNECTION = DB::Pg.new(:$conninfo), 'Create DB::Pg object';
}

my $user;
subtest 'Create user' => {
    plan 2;
    ok $user = Agrammon::DB::User.new(
        :username<agtestuser>,
    ), 'Create new user';
    is $user.username, 'agtestuser', 'User has correct username';
}

subtest 'Create dataset' => {
    plan 10;
    my $date = DateTime.new('2020-04-01T00:00:00Z');
    ok my $dataset = Agrammon::DB::Dataset.new(
        :id<42>,
        :name<agtest>,
        :read-only,
        :model<TestModel>,
        :comment('Test comment'),
        :version('6.0-test'),
        :records(42),
        :mod-date($date),
        :data(),
        :tags()
        :$user
    ), 'Create new dataset';
    is $dataset.name,     'agtest', 'User has correct username';
    is $dataset.read-only, True,     'Dataset is read-only';
    is $dataset.model,     'TestModel',     'User has correct model';
    is $dataset.comment,   'Test comment',     'User has correct comment';
    is $dataset.version,     '6.0-test',     'User has correct version';
    is $dataset.records,     42,     'User has correct records';
    is $dataset.mod-date,    $date,     'User has correct mod-date';
    is $dataset.data.elems,  0,     'User has 0 data';
    is $dataset.tags.elems,  0,     'User has 0 tags';
}


transactionally {
    my $dataset-name = 'agtest';
    my $password = 'XP';
    my $uid;
    my $dataset;
    my $dataset-id;

    subtest 'create-account()' => {
        plan 2;
        ok $user = Agrammon::DB::User.new(
                :username<agtest>,
                :firstname<XF>,
                :lastname<XL>,
                :organisation<XO>,
                :$password,
                ), 'Create new user account';
        ok $uid = $user.create-account('user').id, "Create account, uid=$uid";
    }

    ok prepare-test-db($uid), 'Test database prepared';

    subtest 'create()' => {
        plan 2;
        ok $dataset = Agrammon::DB::Dataset.new(
                :name<agtest>,
                :$user
                ), "Create dataset object";
        ok $dataset-id = $dataset.create().id, "Create dataset, id=$dataset-id";
    }

    subtest 'rename()' => {
        plan 2;
        is $dataset.rename($dataset-name ~ '1'), $dataset-name ~ '1', "Dataset has correct new name";
        is $dataset.rename($dataset-name), $dataset-name, "Dataset has correct old name";
    }

    subtest 'store-comment()' => {
        plan 2;
        is $dataset.store-comment('Dataset comment'), 1, 'Store dataset comment';
        is $dataset.comment, 'Dataset comment', "Dataset has right comment";
    }

    subtest 'store-input()' => {
        is $dataset.store-input("my-variable", 42), 1, "Store single input";
        is $dataset.store-input("my-multi-variable[Branch]::test", 43), 1, "Store multi input";
    }

    subtest 'store-input-comment()' => {
        is $dataset.store-input-comment('my-variable', 'Single input comment'), 1, "Store single input comment";
        is $dataset.store-input-comment('my-multi-variable[Branch]::test', 'Multi input comment'), 1, "Store multi input comment";
    }

    subtest 'load()' => {
        plan 7;
        ok $dataset.load(), 'Load dataset';
        my @row = $dataset.data[0];
        is @row[0], 'my-multi-variable[Branch]::test', "Input has right name";
        is @row[1], 43, "Input has right value";
        is @row[4], 'Multi input comment', "Input has right comment";
        @row = $dataset.data[1];
        is @row[0], 'my-variable', "Input has right name";
        is @row[1], 42, "Input has right value";
        is @row[4], 'Single input comment', "Input has right comment";
    }

    subtest 'Store and load branch data' => {
        plan 6;

        # TODO: cleanup data sent by the frontend
        my $data = %(
            :data($[
                ["0", "5", "0", "0", "0", "0"],
                ["0", "0", "10", "7", "0", "0"],
                ["13", "20", "0", "0", "0", "22"],
                ["0", "15", "0", "8", "0", "0"]]
            ),
            :dataset_name("BranchTest"),
            :instance("Branched"),
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
                    "no manure belt"]
                }),
            :tdata($[
                ["manure belt with manure belt drying system", "0", "5", "0", "0", "0", "0"],
                ["manure belt without manure belt drying system", "0", "0", "10", "7", "0", "0"],
                ["deep pit", "13", "20", "0", "0", "0", "22"],
                ["deep litter", "0", "15", "0", "8", "0", "0"]
            ]),
            :vars($[
                "Livestock::Poultry[]::Housing::Type::housing_type",
                "Livestock::Poultry[]::Housing::Type::manure_removal_interval"
            ]),
            :voptions($[
                ["manure belt with manure belt drying system", "manure belt without manure belt drying system", "deep pit", "deep litter"],
                ["less than twice a month", "twice a month", "3 to 4 times a month", "more than 4 times a month", "once a day", "no manure belt"]
            ])
        );
        my $name = $data<dataset_name>;
        ok $dataset = Agrammon::DB::Dataset.new(:$name, :$user), "Create dataset object";
        ok $dataset.load, "Dataset id=$dataset-id loaded";

        lives-ok { $dataset.store-branch-data(
            $data<vars>, $data<instance>, $data<options>, $data<data>
        ) }, "Store branch data";

        my $results;
        ok $results = $dataset.load-branch-data($data<vars>, $data<instance>), 'Load branch data';

        my @fractions-expected = (
            0e0, 5e0, 0e0, 0e0, 0e0, 0e0,     0e0, 0e0, 10e0, 7e0, 0e0, 0e0,
            13e0, 20e0, 0e0, 0e0, 0e0, 22e0,  0e0, 15e0, 0e0, 8e0,    0e0,    0e0,
        );
        my @options-expected = (
            [<
                manure_belt_with_manure_belt_drying_system
                manure_belt_without_manure_belt_drying_system
                deep_pit
                deep_litter
            >],
            [<
                less_than_twice_a_month
                twice_a_month
                3_to_4_times_a_month
                more_than_4_times_a_month
                once_a_day
                no_manure_belt
            >],
        );
        is-deeply $results<options>,   @options-expected,   "Got correct options";
        is-deeply $results<fractions>, @fractions-expected, "Got correct fractions";
    }

# TODO
# order instances
# delete-instance
# rename-instance
# clone
}

done-testing;
