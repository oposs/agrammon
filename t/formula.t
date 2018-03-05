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

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        In(agricultural_area) * Tech(er_agricultural_area);
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('agricultural_area',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('er_agricultural_area',), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { agricultural_area => 3 },
        technical => { er_agricultural_area => 101 }
    ));
    is $result, 3 * 101, 'Correct result from evaluation';
}, 'Can parse/interpret * operator';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        In(solid_digestate) * Tech(er_solid_digestate) +
        In(compost) * Tech(er_compost);
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('solid_digestate', 'compost',),
        'Correct inputs-used';
    is-deeply $f.technical-used, ('er_solid_digestate', 'er_compost'),
        'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { solid_digestate => 3, compost => 5 },
        technical => { er_solid_digestate => 10, er_compost => 4 }
    ));
    is $result, 3 * 10 + 5 * 4, 'Correct result from evaluation';
}, 'Correct precedence of * and + operators';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        Val(nh3_nmineralfertiliser, PlantProduction::MineralFertiliser) +
        Val(nh3_nrecyclingfertiliser, PlantProduction::RecyclingFertiliser)
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    my @output-used = $f.output-used;
    is @output-used.elems, 2, 'Have 2 output used';
    is @output-used[0].module, 'PlantProduction::MineralFertiliser',
        'Correct first output used module';
    is @output-used[0].symbol, 'nh3_nmineralfertiliser',
        'Correct first output used symbol';
    is @output-used[1].module, 'PlantProduction::RecyclingFertiliser',
        'Correct second output used module';
    is @output-used[1].symbol, 'nh3_nrecyclingfertiliser',
        'Correct second output used symbol';
    my $result = $f.evaluate(Agrammon::Environment.new(
        output => {
            'PlantProduction::MineralFertiliser' => {
                'nh3_nmineralfertiliser' => 12
            },
            'PlantProduction::RecyclingFertiliser' => {
                nh3_nrecyclingfertiliser => 15
            }
        }
    ));
    is $result, 12 + 15, 'Correct result from evaluation';
}, 'Val(...) + Val(...)';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        my $a;
        $a = In(compost);
        my $b = In(compost);
        $b = $b + $b;
        $a * $b
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('compost',), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { compost => 55 }
    ));
    is $result, 55 * (55 + 55), 'Correct result from evaluation';
}, 'Variable declaration, assignment, and lookup';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        3 * In(compost) + 20
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('compost',), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { compost => 55 }
    ));
    is $result, 3 * 55 + 20, 'Correct result from evaluation';
}, 'Integer literals';

done-testing;
