use v6;
use Agrammon::Config;
use Agrammon::DB::User;
use DB::Pg;

use Test;
plan 5;

my $cfg-file = "t/test-data/agrammon.cfg.yaml";
my $username = 'fritz.zaucker@oetiker.ch';

my $cfg = Agrammon::Config.new;
ok $cfg.load($cfg-file), "Load config from file $cfg-file";

my $conninfo;
if (%*ENV<TRAVIS>) {
    my $db-host     = 'localhost';
    my $db-user     = 'postgres';
    my $db-password = '';
    my $db-database = 'agrammon_test';
    
    $conninfo = "host=$db-host user=$db-user password=$db-password dbname=$db-database";
}
else {
    $conninfo = $cfg.db-conninfo;
}

ok my $*AGRAMMON-DB-CONNECTION = DB::Pg.new(:$conninfo), 'Create DB::Pg object';

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
    my $uid;
    subtest 'create-account()' => {
        ok my $user = Agrammon::DB::User.new(
            :$username,
            :firstname<XF>,
            :lastname<XL>,
            :organisation<XO>,
            :password<XP>,
        ), 'Create new user';
        ok $uid = $user.create-account('admin'), "Create account, uid=$uid";
        is $user.username, $username, "Username is $username";
        is $user.role.name, 'admin', "User role is admin";
        throws-like {$uid = $user.create-account('admin')},
                    X::Agrammon::DB::User::Exists, "Cannot create existing account";
    }

    subtest 'load()' => {
        ok my $new-user = Agrammon::DB::User.new, "Create another Agrammon::DB::User object";
        ok $new-user.load($username),             "Load new user";
        is $new-user.id, $uid,                    "Id is $uid";
        is $new-user.username, $username,         "Username is $username";
    }
}

done-testing;

sub transactionally(&test) {
    my $*AGRAMMON-DB-HANDLE = my $db = $*AGRAMMON-DB-CONNECTION.db;
    $db.begin;
    test($db);
    $db.finish;
}

