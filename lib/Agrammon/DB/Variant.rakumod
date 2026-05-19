use v6;

use Agrammon::DB;

role Agrammon::DB::Variant does Agrammon::DB {

    has %.agrammon-variant is required;

    method !variant {
        return %!agrammon-variant<version gui model>;
    }

    # List of dataset_version values this deployment accepts in addition
    # to its own. Used by Dataset.ensure-version-match to claim rows
    # tagged with a compatible (older) Model.version on first open.
    method !compatible-versions {
        (%!agrammon-variant<compatible-versions> // ()).list;
    }
}
