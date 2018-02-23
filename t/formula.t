use v6;
use Agrammon::Environment;
use Agrammon::Formula;
use Agrammon::Formula::Parser;
use Test;

subtest {
    my $f = parse-formula('In(agricultural_area)');
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('agricultural_area',), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { agricultural_area => 42 }
    ));
    is $result, 42, 'Correct result from evaluation';
}, 'In(...)';

subtest {
    my $f = parse-formula('In(agricultural_area);');
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('agricultural_area',), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { agricultural_area => 42 }
    ));
    is $result, 42, 'Correct result from evaluation';
}, 'Semicolon at end of expression';

subtest {
    my $f = parse-formula('Tech(er_agricultural_area)');
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, ('er_agricultural_area',), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        technical => { er_agricultural_area => 101 }
    ));
    is $result, 101, 'Correct result from evaluation';
}, 'Tech(...)';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        Val(mineral_nitrogen_fertiliser_urea, PlantProduction::MineralFertiliser);
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    my @output-used = $f.output-used;
    is @output-used.elems, 1, 'Have 1 output used';
    is @output-used[0].module, 'PlantProduction::MineralFertiliser',
        'Correct output used module';
    is @output-used[0].symbol, 'mineral_nitrogen_fertiliser_urea',
        'Correct output used symbol';
    my $result = $f.evaluate(Agrammon::Environment.new(
        output => {
            'PlantProduction::MineralFertiliser' => {
                'mineral_nitrogen_fertiliser_urea' => 45
            }
        }
    ));
    is $result, 45, 'Correct result from evaluation';
}, 'Val(...)';

done-testing;
