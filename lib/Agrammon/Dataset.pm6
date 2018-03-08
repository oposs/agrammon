use v6;
use Agrammon::User;

class Agrammon::Dataset {
    has Int $.id;
    has Str $.name;
    has Bool $.read-only;
    has Str $.model;
    has Str $.comment;
    has Str $.version;
    has DateTime $.mod-date;
    has Agrammon::User $.user;

    method create {
    }
    
}
