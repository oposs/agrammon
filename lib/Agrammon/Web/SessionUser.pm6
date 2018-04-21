use v6;
use Cro::HTTP::Auth;
use Agrammon::DB::User;

class Agrammon::Web::SessionUser is Agrammon::DB::User does Cro::HTTP::Auth {
    has Bool $.logged-in = False;

    method auth($username, $password) {
        $!logged-in = self.password-is-valid($username, $password);

        if $!logged-in {
            self.set-username($username);
            self.load;
        }
        return self;
    }

}
