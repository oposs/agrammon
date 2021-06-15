use v6;

use Agrammon::DB;

role Agrammon::DB::Variant does Agrammon::DB {

    has %.agrammon-variant is required;

    method !variant {
        return %!agrammon-variant<version gui model>;
    }
    
}
