use v6;
use Agrammon::User;

use Test;

my $username = 'fritz.zaucker@oetiker.ch';

ok my $user = Agrammon::User.new, "Create Agrammon::User object";
ok $user.load($username),         "Load user $username";
is $user.username, $username,     "User has username $username";
is $user.role.name, 'admin',      "User has role admin";
is $user.firstname, 'Fritz',      "User has firstname Fritz";
is $user.lastname, 'Zaucker',     "User has lastname Zaucker";

done-testing;
