use v6;
use Agrammon::Tag;
use Agrammon::User;

class Agrammon::Tags {
    has Agrammon::User $.user;
    has Agrammon::Tag @.collection;
    
    method create {
    }
    
}
