use v6;
use Cro::HTTP::Auth;
use Agrammon::DB;
use Agrammon::DB::User;

class Agrammon::Web::SessionUser is Agrammon::DB::User does Cro::HTTP::Auth {
    has Bool $.logged-in = False;
    has Str $.sudo-username;

    method auth($username, $password, $sudo-username?) {
        if $sudo-username {
            die X::Agrammon::DB::User::MayNotSudo.new(:username($sudo-username)) unless self.may-sudo;
            $!sudo-username = $sudo-username;
        }
        else {
            $!logged-in = self.password-is-valid($username, $password);
            die X::Agrammon::DB::User::InvalidPassword.new unless $!logged-in;

        }

        self.set-username($username);
        self.load;
        self.with-db: -> $db {
                $db.query(q:to/SQL/, $.id, $!sudo-username);
                    INSERT INTO login (login_pers, login_sudouser)
                    VALUES ($1, $2)
                SQL
                # die X::Agrammon::DB::User::CreateFailed.new(:$!username) unless $ret.rows;
        }
        return self;
    }

    method logout() {
        my $old-username;
        if $!sudo-username {
            $old-username = self.username;
            self.set-username($!sudo-username);
            self.load;
            $!sudo-username = Nil;
        }
        else {
            $!logged-in = False;
        }
        return $old-username;
    }

    method may-sudo {
        return $!logged-in && self.role.name eq 'admin' | 'support';
    }

    # Add what's needed to be persisted to database
    method to-json() {
        { :$!logged-in, :$.username, |(:$!sudo-username if $!sudo-username) }
    }

    method from-json((:$logged-in = False, :$username = Str, :$sudo-username = Str)) {
        self.new(:$logged-in, :$username, :$sudo-username).load
    }

}
