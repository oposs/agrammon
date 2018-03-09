use v6;
use Agrammon::DB::User;
use Agrammon::DB::Tag;

class Agrammon::DB::Tags {
    has Agrammon::DB::User $.user;
    has Agrammon::DB::Tag @.collection;
    
    method load {
        ...
    }
    
}
