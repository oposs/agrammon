use v6;
use Cro::HTTP::Auth;
use Agrammon::DB::User;

class Agrammon::Web::UserSession is Agrammon::DB::User does Cro::HTTP::Auth {
#    has $.username is rw;
#    has $.is-admin;
#    has $.is-logged-in;

    method logged-in() {
        return defined self.username;
    }

    method auth($username, $password) {
        self.with-db: -> $db {
            my %p = $db.query(q:to/PERS/, $username).hash;
                SELECT pers_password AS password
                  FROM pers
                 WHERE pers_email = $1
            PERS

            return $password eq %p<password>;
        }
    }
}
