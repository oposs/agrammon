use v6;
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

class X::Agrammon::DB::User::CreateFailed is Exception {
    has Str $.user-name is required;

    method message {
        "Couldn't create user $.username";
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

    method create-account(Str $role-name) {
        die X::Agrammon::DB::User::Exists.new(:username($!username)) if self.exists;

        self.with-db: -> $db {
            my %r = $db.query(q:to/ROLE/, $role-name).hash;
                SELECT role_id   AS id,
                       role_name AS name
                  FROM role
                 WHERE role_name = $1
            ROLE
            $!role = Agrammon::DB::Role.new(|%r);

            my $u = $db.query(q:to/USER/, $!username, $!firstname, $!lastname, $!password, $!organisation, %r<id> );
                INSERT INTO pers (pers_email, pers_first, pers_last,
                                  pers_password, pers_org, pers_role)
                VALUES ($1, $2, $3, crypt($4, gen_salt('bf')), $5, $6)
                RETURNING pers_id
            USER
            $!id = $u.value;
        }
        return self;
    }

    method load {
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

    method exists {
        self.with-db: -> $db {
            my $uid = $db.query(q:to/USER/, $!username).value;
                SELECT pers_id AS id
                  FROM pers
                 WHERE pers_email = $1
            USER
            return $uid;
        }
    }

    method password-is-valid(Str $username, Str $password) {
        self.with-db: -> $db {
            return $db.query(q:to/PERS/, $username, $password).value;
            SELECT crypt($2, pers_password) = pers_password
                  FROM pers
                 WHERE pers_email = $1
            PERS
        }
    }

    method change-password($old, $new) {
        self.with-db: -> $db {

           if self.password-is-valid($!username, $old) {
                my $res = $db.query(q:to/PASSWORD/, $!username, $new);
                    UPDATE pers
                       SET pers_password = crypt($2, gen_salt('bf'))
                     WHERE pers_email    = $1
                PASSWORD

                my $valid = self.password-is-valid($!username, $new);
                if not $valid {
                    warn 'PW update failed';
                }
                return $valid;
            }
            else {
                warn "Invalid old pw: $old";
            }
        }
        return False;
    }

    method password-key-is-valid(Str $password, Str $key) {
        warn "TODO: Password hash check missing";
        return $key;
    }


    method reset-password($username, $password, $key) {
        self.with-db: -> $db {

            if self.password-key-is-valid($username, $key) {
                my $res = $db.query(q:to/PASSWORD/, $username, $password);
                    UPDATE pers
                       SET pers_password = crypt($2, gen_salt('bf'))
                     WHERE pers_email    = $1
                PASSWORD

                return $res;
            }
            else {
                warn "Invalid password key";
            }
        }
        return;
    }

}
