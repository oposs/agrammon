use v6;
use Cro::HTTP::Auth;
use Agrammon::DB::User;

class Agrammon::Web::UserSession is Agrammon::DB::User does Cro::HTTP::Auth {
#    has $.username is rw;
#    has $.is-admin;
#    has $.is-logged-in;

    method logged-in() {
#        say "*** username=", $!username // 'NONE';
#        defined $!username;
        say "*** username=", self.username // 'NONE';
        defined self.username;
   }
}
