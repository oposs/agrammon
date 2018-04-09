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

class Agrammon::DB::User does Agrammon::DB {
    has Int $.id;
    has Str $.username;
    has Str $.firstname;
    has Str $.lastname;
    has Str $.password;
    has Str $.organisation;
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
                VALUES ($1, $2, $3, crypt($4, gen_salt('md5')), $5, $6)
                RETURNING pers_id
            USER

            $!id = $u.value;
        }
        return $!id;
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
#            $!password     = $u<password>;
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


}
