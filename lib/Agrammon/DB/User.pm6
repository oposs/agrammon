use v6;

use Digest::SHA1::Native;

use Agrammon::DB;
use Agrammon::DB::Role;

class X::Agrammon::DB::User::Exists is Exception {
    has $.username;
    method message() {
        "Account $!username already exists!";
    }
}

class X::Agrammon::DB::User::NoUsername is Exception {
    method message() {
        "Need username to load user from database!";
    }
}

class X::Agrammon::DB::User::CannotSetRole is Exception {
    method message() {
        "Only admin users can create accounts with roles!";
    }
}

class X::Agrammon::DB::User::CannotResetPassword is Exception {
    method message() {
        "Only admin users can reset other users' password!";
    }
}

class X::Agrammon::DB::User::CreateFailed is Exception {
    has Str $.username is required;
    method message {
        "Couldn't create user $!username";
    }
}

class X::Agrammon::DB::User::NoPassword is Exception {
    method message() {
        "Need password to create an account!";
    }
}

class X::Agrammon::DB::User::UnknownRole is Exception {
    has Str $.role is required;
    method message {
        "Role '$!role' doesn't exist.";
    }
}

class X::Agrammon::DB::User::PasswordResetFailed is Exception {
    method message() {
        "Invalid username or password";
    }
}

class X::Agrammon::DB::User::InvalidPassword is Exception {
    method message() {
        "Invalid username or password";
    }
}

class X::Agrammon::DB::User::UnknownUser is Exception {
    has Str $.username is required;
    method message() {
        "User '$!username' has no Agrammon account";
    }
}

class X::Agrammon::DB::User::MayNotSudo is Exception {
    has Str $.username is required;
    method message() {
        "User '$!username' may not change to another account";
    }
}

class X::Agrammon::DB::User::PasswordsIdentical is Exception {
    method message() {
        "Old and new password must be different";
    }
}

class Agrammon::DB::User does Agrammon::DB {
    has Int $.id;
    has Str $.username;
    has Str $.password;
    has $.firstname;
    has $.lastname;
    has $.organisation;
    has DateTime $.last-login;
    has DateTime $.created;
    has Agrammon::DB::Role $.role;

    method set-username(Str $username) {
        $!username = $username;
    }

    method is-admin {
        $!role.is-admin
    }

    sub get-password-key($username, $password) {
        my $secret = '987ew9d%skjh/fH;K,JHKH';
        my $digest = sha1-hex($username ~ $password ~ $secret);
        # only easily human readable characters
        return substr($digest ~~ tr/1/x/, 5, 6);
    }

    method get-account-key() {
        die X::Agrammon::DB::User::NoUsername.new(:$!username) unless $!username;
        die X::Agrammon::DB::User::NoPassword.new unless $!password;

        get-password-key($!username, $!password)
    }

    method create-account($role-name) {
        my $role = $role-name || 'user';
        die X::Agrammon::DB::User::Exists.new(:$!username) if self.exists;
        die X::Agrammon::DB::User::NoUsername.new(:$!username) unless $!username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $role);
                SELECT role_id   AS id,
                       role_name AS name
                  FROM role
                 WHERE role_name = $1
            SQL
            die X::Agrammon::DB::User::UnknownRole.new(:$role) unless $ret.rows;

            my %r = $ret.hash;
            $!role = Agrammon::DB::Role.new(|%r);

            $ret = $db.query(q:to/SQL/, $!username, $!firstname, $!lastname, $!password, $!organisation, %r<id> );
                INSERT INTO pers (pers_email, pers_first, pers_last,
                                  pers_password, pers_org, pers_role)
                VALUES ($1, $2, $3, crypt($4, gen_salt('bf')), $5, $6)
                RETURNING pers_id
            SQL

            die X::Agrammon::DB::User::CreateFailed.new(:$!username) unless $ret.rows;

            $!id = $ret.value;
        }
        return self;
    }

    method load() {
        die X::Agrammon::DB::User::NoUsername.new unless $!username;
        self.with-db: -> $db {
            my $u = $db.query(q:to/USER/, $!username).hash;
                SELECT pers_id         AS id,
                       pers_email      AS username,
                       pers_first      AS firstname,
                       pers_last       AS lastname,
                       pers_password   AS password,
                       pers_org        AS organisation,
                       pers_last_login AS "last-login",
                       pers_created    AS created,
                       pers_role       AS "role-id"
                  FROM pers
                 WHERE pers_email = $1
            USER

            # how can this be done more compactly
            $!id           = $u<id>;
            $!username     = $u<username>;
            $!firstname    = $u<firstname>;
            $!lastname     = $u<lastname>;
            $!organisation = $u<organisation>;
            $!last-login   = $u<last-login>;
            $!created      = $u<created>;

            my %r = $db.query(q:to/ROLE/, $u<role-id>).hash;
                SELECT role_id   AS id,
                       role_name AS name
                  FROM role
                 WHERE role_id = $1
            ROLE
            $!role = Agrammon::DB::Role.new(|%r);
        }
        return self;
    }

    method exists() {
        my $uid;
        self.with-db: -> $db {
            $uid = $db.query(q:to/USER/, $!username).value;
                SELECT pers_id AS id
                  FROM pers
                 WHERE pers_email = $1
            USER
        }
        return $uid;
    }

    method password-is-valid(Str $username, Str $password) {
        self.with-db: -> $db {
            return $db.query(q:to/SQL/, $username, $password).value;
                SELECT crypt($2, pers_password) = pers_password
                  FROM pers
                 WHERE pers_email = $1
            SQL
        }
    }

    method change-password($old, $new) {
        self.with-db: -> $db {

            die X::Agrammon::DB::User::InvalidPassword.new    unless self.password-is-valid($!username, $old);
            die X::Agrammon::DB::User::PasswordsIdentical.new if $old eq $new;

            $db.query(q:to/SQL/, $!username, $new);
                UPDATE pers
                    SET pers_password = crypt($2, gen_salt('bf'))
                    WHERE pers_email  = $1
                RETURNING pers_email
            SQL

            die X::Agrammon::DB::User::InvalidPassword.new unless self.password-is-valid($!username, $new);
        }
    }

    sub password-key-is-valid(Str $username, Str $password, Str $key) {
        get-password-key($username, $password) eq $key
    }

    method reset-password($email, $password, $key?) {
        # self reset, anonymous user
        if $key and not password-key-is-valid($email, $password, $key) {
            die X::Agrammon::DB::User::CannotResetPassword.new;
        }
        self.with-db: -> $db {
            $db.query(q:to/SQL/, $email, $password);
                UPDATE pers
                   SET pers_password = crypt($2, gen_salt('bf'))
                 WHERE pers_email = $1
                RETURNING pers_email
                SQL
            die X::Agrammon::DB::User::PasswordResetFailed.new unless self.password-is-valid($email, $password);
        }
    }

}
