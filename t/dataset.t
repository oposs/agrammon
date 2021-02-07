use v6;
use Agrammon::Config;
use Agrammon::DB::Dataset;
use Agrammon::DB::User;
use Agrammon::Web::SessionUser;
use DB::Pg;
use Test;

# plan 6;

if %*ENV<AGRAMMON_UNIT_TEST> {
    skip-rest 'Not a unit test';
    exit;
}

my $*AGRAMMON-DB-CONNECTION;

subtest 'Connect to database' => {
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
    ok $user = Agrammon::DB::User.new(
        :username<agtestuser>,
    ), 'Create new user';
    is $user.username, 'agtestuser', 'User has correct username';
}

subtest 'Create dataset' => {
    my $date = DateTime.new('2020-04-01T00:00:00Z');
    diag $date;
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
        :user($user)
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
#    is $dataset.user.username,   'agtestuser',     'User has correct user';
}

# done-testing; exit;

transactionally {
    my $dataset-name = 'agtest';
    my $password = 'XP';
    my $uid;
    my $dataset;
    my $dataset-id;

    ok prepare-test-db, 'Test database prepared';

    subtest 'create-account()' => {
        ok $user = Agrammon::DB::User.new(
                :username<agtest>,
                :firstname<XF>,
                :lastname<XL>,
                :organisation<XO>,
                :$password,
                ), 'Create new user account';
        ok $uid = $user.create-account('user').id, "Create account, uid=$uid";

    }

    subtest 'create()' => {
        ok $dataset = Agrammon::DB::Dataset.new(
                :name<agtest>,
                :$user
                ), "Create dataset object";
        ok $dataset-id = $dataset.create().id, "Create dataset, id=$dataset-id";
    }

    subtest 'rename()' => {
        is $dataset.rename($dataset-name ~ '1'), $dataset-name ~ '1', "Dataset has correct new name";
        is $dataset.rename($dataset-name), $dataset-name, "Dataset has correct old name";
    }

    subtest 'store-comment()' => {
        is $dataset.store-comment('Dataset comment'), 1, 'Store dataset comment';
        is $dataset.comment, 'Dataset comment', "Dataset has right comment";
    }

    subtest 'store-input-comment()' => {
        is $dataset.store-input-comment('my-variable', 'Input comment'), 1, "Store single input comment";
    }

    subtest 'store-input()' => {
        is $dataset.store-input("my-variable", 42), 1, "Store single input";
    }

    subtest 'load()' => {
        ok $dataset.load(), 'Load dataset';
        my @row = $dataset.data[0];
        is @row[0], 'my-variable', "Input has right name";
        is @row[1], 42, "Input has right value";
        is @row[4], 'Input comment', "Input has right comment";
    }

# TODO
# order instances
# delete-instance
# rename-instance
# clone

}

done-testing;

sub prepare-test-db {
    my $db = $*AGRAMMON-DB-HANDLE;

    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS role (
        role_id       SERIAL NOT NULL PRIMARY KEY, -- Unique ID
        role_name     TEXT NOT NULL UNIQUE
    )
    SQL

    my $results = $db.query(q:to/SQL/);
    SELECT role_id
      FROM role
    SQL

    my @ids = $results.arrays.sort;
    if not @ids eqv [[0],[1],[2]] {
        my $sth = $db.prepare(q:to/SQL/);
            INSERT INTO role (role_id, role_name)
            VALUES ($1, $2)
        SQL
        $sth.execute(0, 'admin');
        $sth.execute(1, 'user');
        $sth.execute(2, 'support');
    }

    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS pers (
        pers_id         SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
        pers_email      TEXT NOT NULL UNIQUE,                    -- used as login name
        pers_first      TEXT NOT NULL CHECK (pers_first != ''),  -- First Name of Person
        pers_last       TEXT NOT NULL CHECK (pers_last != ''),   -- Last Name of Person
        pers_password   TEXT NOT NULL,                           -- Password
        pers_org        TEXT NOT NULL,                           -- Organisation
        pers_last_login TIMESTAMP WITHOUT TIME ZONE,
        pers_created    TIMESTAMP WITHOUT TIME ZONE,
        pers_role       INTEGER NOT NULL REFERENCES role(role_id) DEFAULT 1
    )
    SQL

    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS dataset (
        dataset_id       SERIAL NOT NULL PRIMARY KEY,                 -- Unique ID
        dataset_name     TEXT NOT NULL,                               -- dataset name
        dataset_pers     INTEGERT NOT NULL REFERENCES pers(pers_id),  -- owner
        dataset_version  TEXT DEFAULT '2.0',                          -- Version
        dataset_comment  TEXT,
        dataset_model    TEXT,
        dataset_readonly BOOLEAN DEFAULT False
    )
    SQL

    return 1;
}

sub transactionally(&test) {
    my $*AGRAMMON-DB-HANDLE = my $db = $*AGRAMMON-DB-CONNECTION.db;
    $db.begin;
    test($db);
    $db.finish;
}
