use v6;
use Agrammon::Config;
use Agrammon::DB::User;
use DB::Pg;
use Test;

plan 5;

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

subtest 'Create user' => {
    ok my $user = Agrammon::DB::User.new(
        :username<agtest>,
        :firstname<XF>,
        :lastname<XL>,
        :organisation<XO>,
        :password<XP>,
    ), 'Create new user';
    is $user.username,     'agtest', 'User has correct username';
    is $user.firstname,    'XF',     'User has correct firstname';
    is $user.lastname,     'XL',     'User has correct lastname';
    is $user.organisation, 'XO',     'User has correct organisation';
    is $user.password,     'XP',     'User has correct password';
}

transactionally {
    my $username = 'agtest';
    my $password = 'XP';
    my $uid;
    my $new-user;

    ok prepare-test-db, 'Test database prepared';

    subtest 'create-account()' => {
        ok my $user = Agrammon::DB::User.new(
            :$username,
            :firstname<XF>,
            :lastname<XL>,
            :organisation<XO>,
            :$password,
        ), 'Create new user';
        ok $uid = $user.create-account('admin'), "Create account, uid=$uid";
        is $user.username, $username, "Username is $username";
        is $user.role.name, 'admin', "User role is admin";
        throws-like {$uid = $user.create-account('admin')},
                    X::Agrammon::DB::User::Exists, "Cannot create existing account";
    }

    subtest 'load()' => {
        ok $new-user = Agrammon::DB::User.new, "Create Agrammon::DB::User object without username";
        throws-like {$new-user.load}, X::Agrammon::DB::User::NoUsername, "No username";
        ok $new-user = Agrammon::DB::User.new(:$username), "Create another Agrammon::DB::User object with username";
        ok $new-user.load,                "Load new user";
        is $new-user.username, $username, "Username is $username";
    }

}

done-testing;

sub prepare-test-db {
    my $db = $*AGRAMMON-DB-HANDLE;

    $db.query(q:to/STATEMENT/);
    CREATE TABLE IF NOT EXISTS role (
        role_id       SERIAL NOT NULL PRIMARY KEY, -- Unique ID
        role_name     TEXT NOT NULL UNIQUE
    )
    STATEMENT

    my $results = $db.query(q:to/STATEMENT/);
    SELECT role_id
      FROM role
    STATEMENT

    my @ids = $results.arrays.sort;
    if not @ids eqv [[0],[1],[2]] {
        my $sth = $db.prepare(q:to/STATEMENT/);
            INSERT INTO role (role_id, role_name)
            VALUES ($1, $2)
        STATEMENT
        $sth.execute(0, 'admin');
        $sth.execute(1, 'user');
        $sth.execute(2, 'support');
    }

    $db.query(q:to/STATEMENT/);
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
    STATEMENT

    return 1;
}

sub transactionally(&test) {
    my $*AGRAMMON-DB-HANDLE = my $db = $*AGRAMMON-DB-CONNECTION.db;
    $db.begin;
    test($db);
    $db.finish;
}
