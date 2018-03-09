use v6;
use Agrammon::DB::User;

use Test;
plan 7;

my $cfg-file = "t/test-data/agrammon.cfg.yaml";
my $username = 'fritz.zaucker@oetiker.ch';

my $cfg = Agrammon::Config.new;
ok $cfg.load($cfg-file), "Load config from file $cfg-file";

ok my $user = Agrammon::DB::User.new, "Create Agrammon::DB::User object";
if (%*ENV<TRAVIS>) {
    skip-rest('Not set up for Travis yet');
    exit;
}
ok $user.load($username, $cfg),       "Load user $username";
is $user.username, $username,         "User has username $username";
is $user.role.name, 'admin',          "User has role admin";
is $user.firstname, 'Fritz',          "User has firstname Fritz";
is $user.lastname, 'Zaucker',         "User has lastname Zaucker";

done-testing;
