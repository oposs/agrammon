use v6;
use Agrammon::DB::User;

class Agrammon::DB::Tag {
    has Str $.name;
    has Agrammon::DB::User $.user;

    method create {
        ...
    }
    
}
