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
