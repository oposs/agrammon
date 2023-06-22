use v6;
use Agrammon::Outputs::FilterGroupCollection;

multi sub flat-value($value) is export {
    $value
}
multi sub flat-value(Agrammon::Outputs::FilterGroupCollection $collection) is export {
    +$collection
}

sub sorted-kv($_) is export {
    .sort(*.key).map({ |.kv })
}

sub module-with-instance($module-root, $instance-id, $module-full) is export {
    $module-root ~ '[' ~ $instance-id ~ ']' ~ $module-full.substr($module-root.chars);
}
