use v6;
use Cro::HTTP::Auth;
use Agrammon::DB::User;

class Agrammon::Web::SessionUser is Agrammon::DB::User does Cro::HTTP::Auth {
    has Bool $.logged-in = False;

    method auth($username, $password) {
        $!logged-in = self.password-is-valid($username, $password);

        die X::Agrammon::DB::User::InvalidPassword.new unless $!logged-in;

        self.set-username($username);
        self.load;
        return self;
    }

    method to-json() {
        { :$!logged-in, :$.username }
    }

    method from-json((:$logged-in = False, :$username = Str)) {
        self.new(:$logged-in, :$username).load
    }
}
