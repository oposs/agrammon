use Agrammon::Outputs::FilterGroupCollection;
use Test;

given Agrammon::Outputs::FilterGroupCollection.from-scalar(0) {
    is +$_, 0, 'Can construct a collection from a scalar value and it numifies back to that';
    is-deeply .results-by-filter-group,
            [{} => 0],
            'Correct results by filter group from scalar value';
}

{
    my @instances = {} => 4, {} => 7, {} => 31;
    given Agrammon::Outputs::FilterGroupCollection.from-filter-to-value-pairs(@instances) {
        is +$_, 42, 'Total numeric value is correct when constructed from filter to value pairs';
        is-deeply .results-by-filter-group,
                [{} => 42],
                'Correct results by filter group when all instances had empty filter group';
    }
}

{
    my @instances = {ac => 'blue cow'} => 4, {ac => 'pink cow'} => 7, {ac => 'blue cow'} => 31;
    given Agrammon::Outputs::FilterGroupCollection.from-filter-to-value-pairs(@instances) {
        is +$_, 42, 'Total numeric value is correct when different filters exist';
        is-deeply norm(.results-by-filter-group),
                norm([{ac => 'blue cow'} => 35, { ac => 'pink cow' } => 7]),
                'Correct results by filter group when a range of filters';
    }
}

{
    my $group = Agrammon::Outputs::FilterGroupCollection.from-filter-to-value-pairs:
            [{ac => 'blue cow'} => 4, {ac => 'pink cow'} => 7, {ac => 'blue cow'} => 31];
    given $group.scale(2) {
        isa-ok $_, Agrammon::Outputs::FilterGroupCollection,
                'Get another filter group back after scaling';
        is +$group, 42, 'Original filter group is not changed in place';
        is +$_, 84, 'Total numeric value is correct after scaling';
        is-deeply norm(.results-by-filter-group),
                norm([{ac => 'blue cow'} => 70, { ac => 'pink cow' } => 14]),
                'Correct results by filter group after scaling';
    }
}

#| Put filter pairs in a normal order, so we needn't worry about ordering when writing tests.
sub norm(@pairs) {
    [@pairs.sort(*.key.values.sort.join)]
}

done-testing;
