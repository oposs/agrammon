use v6;
use Agrammon::Role;
use DB::Pg;

class Agrammon::User {
    has Int $.id;
    has Str $.username;
    has Str $.firstname;
    has Str $.lastname;
    has Str $.password;
    has Str $.organisation;
    has DateTime $.last-login;
    has DateTime $.created;
    has Agrammon::Role $.role;

    method create {
    }

    method load(Str $username) {
        my $pg = DB::Pg.new(conninfo => 'dbname=agrammon_dev host=erika.oetiker.ch user=agrammon password=agrammon@work');
        my @u = $pg.query(q:to/USER/, $username).array;
            SELECT pers_id,
                   pers_email,
                   pers_first,
                   pers_last,
                   pers_password,
                   pers_org,
                   pers_last_login,
                   pers_created,
                   pers_role
              FROM pers
             WHERE pers_email = $1
        USER

        $!id           = @u[0];
        $!username     = @u[1];
        $!firstname    = @u[2];
        $!lastname     = @u[3];
        $!password     = @u[4];
        $!organisation = @u[5];
        $!last-login   = @u[6];
        $!created      = @u[7];

        my $role-id = @u[8];
        my @r = $pg.query(q:to/ROLE/, $role-id).array;
            SELECT role_id,
                   role_name
              FROM role
             WHERE role_id = $1
        ROLE
        $!role = Agrammon::Role.new(
            id   => @r[0],
            name => @r[1]
        );
    }
    
}
