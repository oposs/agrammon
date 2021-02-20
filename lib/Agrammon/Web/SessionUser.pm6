use v6;
use Cro::HTTP::Auth;
use Agrammon::DB::User;

class Agrammon::Web::SessionUser is Agrammon::DB::User does Cro::HTTP::Auth {
    has Bool $.logged-in = False;
    has Bool $.sudo-user = False;
    has Str $.sudo-username;

    method auth($username, $password, $sudo-username?) {
        if $sudo-username {
            die X::Agrammon::DB::User::MayNotSudo.new(:username($sudo-username)) unless self.may-sudo;

            $!logged-in = True;
            $!sudo-user = True;
            $!sudo-username = $sudo-username;
        }
        else {
            $!logged-in = self.password-is-valid($username, $password);
            die X::Agrammon::DB::User::InvalidPassword.new unless $!logged-in;
        }

        self.set-username($username);
        self.load;
        return self;
    }

    method logout() {
        if $!sudo-user {
            self.set-username($!sudo-username);
            self.load;
            $!sudo-username = Nil;
            $!sudo-user = False;
        }
        else {
            $!logged-in = False;
        }
    }

    method to-json() {
        { :$!logged-in, :$.username }
    }

    method from-json((:$logged-in = False, :$username = Str)) {
        self.new(:$logged-in, :$username).load
    }

    method may-sudo {
        return self.role.name eq 'admin' or ~self.role.name eq 'support';
    }
}
