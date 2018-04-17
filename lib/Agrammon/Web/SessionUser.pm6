use v6;
use Cro::HTTP::Auth;
use Agrammon::DB::User;

class Agrammon::Web::SessionUser is Agrammon::DB::User does Cro::HTTP::Auth {
    has Bool $.logged-in = False;

    method auth($username, $password) {
        self.with-db: -> $db {
            $!logged-in = $db.query(q:to/PERS/, $password, $username).value;
                SELECT (crypt($1, pers_password) = pers_password) AS authenticated
                  FROM pers
                 WHERE pers_email = $2
            PERS
        }

        if $!logged-in {
            self.set-username($username);
            self.load;
        }
        return self;
    }

}
