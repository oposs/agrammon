use Agrammon::Outputs::FilterGroupCollection;
use Test;

given Agrammon::Outputs::FilterGroupCollection.from-scalar(0) {
    nok .has-filters, 'Scalar value has no filters';
    is +$_, 0, 'Can construct a collection from a scalar value and it numifies back to that';
    is-deeply .results-by-filter-group,
            [{} => 0],
            'Correct results by filter group from scalar value';
}

{
    my @instances = {} => 4, {} => 7, {} => 31;
    given Agrammon::Outputs::FilterGroupCollection.from-filter-to-value-pairs(@instances) {
        nok .has-filters, 'If all filters are empty, it has no filters';
        is +$_, 42, 'Total numeric value is correct when constructed from filter to value pairs';
        is-deeply .results-by-filter-group,
                [{} => 42],
                'Correct results by filter group when all instances had empty filter group';
    }
}

{
    my @instances = {ac => 'blue cow'} => 4, {ac => 'pink cow'} => 7, {ac => 'blue cow'} => 31;
    given Agrammon::Outputs::FilterGroupCollection.from-filter-to-value-pairs(@instances) {
        ok .has-filters, 'With filter values set, the collection has filters';
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

{
    my $group = Agrammon::Outputs::FilterGroupCollection.from-filter-to-value-pairs:
            [{ac => 'blue cow'} => 4, {ac => 'pink cow'} => 7, {ac => 'blue cow'} => 31];
    given $group.add(2) {
        isa-ok $_, Agrammon::Outputs::FilterGroupCollection,
                'Get another filter group back after adding scalar';
        is +$group, 42, 'Original filter group is not changed in place';
        is +$_, 46, 'Total numeric value is correct after adding scalar';
        is-deeply norm(.results-by-filter-group),
                norm([{ac => 'blue cow'} => 37, { ac => 'pink cow' } => 9]),
                'Correct results by filter group after adding scalar';
    }
}

{
    my $group = Agrammon::Outputs::FilterGroupCollection.from-filter-to-value-pairs:
            [{ac => 'blue cow'} => -4, {ac => 'pink cow'} => 0, {ac => 'green cow'} => 31, {ac => 'blue cow'} => 2];
    given $group.hashsign() {
        isa-ok $_, Agrammon::Outputs::FilterGroupCollection,
                'Get another filter group back after adding scalar';
        is +$group, 29, 'Original filter group is not changed in place';
        is +$_, 0, 'Total numeric value is correct after adding scalar';
        is-deeply norm(.results-by-filter-group),
                norm([{ac => 'blue cow'} => -1, { ac => 'pink cow' } => 0, { ac => 'green cow' } => 1]),
                'Correct results by filter group after adding scalar';
    }
}

{
    my $group-a = Agrammon::Outputs::FilterGroupCollection.from-filter-to-value-pairs:
            [{ac => 'blue cow'} => 4, {ac => 'pink cow'} => 7, {ac => 'blue cow'} => 31];
    my $group-b = Agrammon::Outputs::FilterGroupCollection.from-filter-to-value-pairs:
            [{ac => 'blue cow'} => 10, {ac => 'green cow'} => 5, {ac => 'green cow'} => 9];
    given $group-a.apply-pairwise($group-b, &[+], 0) {
        isa-ok $_, Agrammon::Outputs::FilterGroupCollection,
                'Applying a pairwise operation produces a new filter group collection';
        is +$group-a, 42, 'First original group unchanged';
        is +$group-b, 24, 'Second original group unchanged';
        is +$_, 42 + 24, 'Total numeric value after pairwise operation is correct';
        is-deeply norm(.results-by-filter-group),
                norm([{ac => 'blue cow'} => 45, { ac => 'pink cow' } => 7, { ac => 'green cow' } => 14]),
                'Correct results by filter group after pairwise operation';
    }
}

#| Put filter pairs in a normal order, so we needn't worry about ordering when writing tests.
sub norm(@pairs) {
    [@pairs.sort(*.key.values.sort.join)]
}

done-testing;
