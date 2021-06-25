use v6;

class Agrammon::DB::Role {
    has Int $.id;
    has Str $.name;

    method is-admin {
        $!name eq 'admin'
    }

}
