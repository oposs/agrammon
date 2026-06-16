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

# Synthetic, language-keyed label for the "uncategorized" filter group. This is
# the empty filter key that arises when a hash filter-group operator (P+, P-, …)
# is applied to a scalar value: the scalar is upgraded into a filter group
# collection and stored under the empty key. Without an explicit label this
# remainder is silently dropped from the breakdown, so totals no longer add up
# (see GitHub issue #209; PR #216 did the same for the text output).
sub uncategorized-filter-label() is export {
    %(
        de => '(nicht zugeordnet)',
        en => '(uncategorized)',
        fr => '(non attribué)',
    )
}
