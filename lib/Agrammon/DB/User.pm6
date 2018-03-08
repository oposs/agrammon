use v6;
use Agrammon::Config;
use Agrammon::DB::Role;
use DB::Pg;

class Agrammon::DB::User {
    has Int $.id;
    has Str $.username;
    has Str $.firstname;
    has Str $.lastname;
    has Str $.password;
    has Str $.organisation;
    has DateTime $.last-login;
    has DateTime $.created;
    has Agrammon::DB::Role $.role;

    method create-account {
        ...
    }

    method load(Str $username, Agrammon::Config $cfg) {
        my $pg = DB::Pg.new(conninfo => $cfg.db-conninfo);
        my $u = $pg.query(q:to/USER/, $username).hash;
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
        $!password     = $u<password>;
        $!organisation = $u<organisation>;
        $!last-login   = $u<last-login>;
        $!created      = $u<created>;

        my %r = $pg.query(q:to/ROLE/, $u<role-id>).hash;
            SELECT role_id   AS id,
                   role_name AS name
              FROM role
             WHERE role_id = $1
        ROLE
        $!role = Agrammon::DB::Role.new(|%r);
    }
    
}
