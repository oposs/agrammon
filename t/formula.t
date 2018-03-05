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

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        my $a;
        if (In(milk_yield) > Tech(standard_milk_yield)) {
            $a = Tech(a_high);
        }
        else {
            $a = Tech(a_low);
        }
        $a
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('milk_yield',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('standard_milk_yield', 'a_high', 'a_low'),
        'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result-true = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 55 },
        technical => { standard_milk_yield => 45, a_high => 10, a_low => 5 }
    ));
    is $result-true, 10, 'Correct result when if condition is true';
    my $result-false = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 35 },
        technical => { standard_milk_yield => 45, a_high => 10, a_low => 5 }
    ));
    is $result-false, 5, 'Correct result when if condition is false';
}, 'if/else construct with > operator';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        my $a;
        if (In(milk_yield) < Tech(standard_milk_yield)) {
            $a = Tech(a_low);
        }
        else {
            $a = Tech(a_high);
        }
        $a
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('milk_yield',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('standard_milk_yield', 'a_low', 'a_high'),
        'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result-true = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 55 },
        technical => { standard_milk_yield => 45, a_high => 10, a_low => 5 }
    ));
    is $result-true, 10, 'Correct result when if condition is false';
    my $result-false = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 35 },
        technical => { standard_milk_yield => 45, a_high => 10, a_low => 5 }
    ));
    is $result-false, 5, 'Correct result when if condition is true';
}, 'if/else construct with < operator';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        my $a;
        if (In(milk_yield) == Tech(standard_milk_yield)) {
            $a = Tech(a_high);
        }
        else {
            $a = Tech(a_low);
        }
        $a
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('milk_yield',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('standard_milk_yield', 'a_high', 'a_low'),
        'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result-true = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 55 },
        technical => { standard_milk_yield => 55, a_high => 10, a_low => 5 }
    ));
    is $result-true, 10, 'Correct result when if condition is true';
    my $result-false = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 35 },
        technical => { standard_milk_yield => 45, a_high => 10, a_low => 5 }
    ));
    is $result-false, 5, 'Correct result when if condition is false';
}, 'if/else construct with == operator';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        my $a;
        if (In(milk_yield) != Tech(standard_milk_yield)) {
            $a = Tech(a_low);
        }
        else {
            $a = Tech(a_high);
        }
        $a
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('milk_yield',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('standard_milk_yield', 'a_low', 'a_high'),
        'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result-true = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 55 },
        technical => { standard_milk_yield => 55, a_high => 10, a_low => 5 }
    ));
    is $result-true, 10, 'Correct result when if condition is false';
    my $result-false = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 35 },
        technical => { standard_milk_yield => 45, a_high => 10, a_low => 5 }
    ));
    is $result-false, 5, 'Correct result when if condition is true';
}, 'if/else construct with != operator';

subtest {
    my $f = parse-formula('return In(agricultural_area)');
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('agricultural_area',), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { agricultural_area => 42 }
    ));
    is $result, 42, 'Correct result from evaluation';
}, 'Simple use of return in last statement';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        if (In(milk_yield) != Tech(standard_milk_yield)) {
            return Tech(a_low);
        }
        Tech(a_high)
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('milk_yield',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('standard_milk_yield', 'a_low', 'a_high'),
        'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result-true = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 55 },
        technical => { standard_milk_yield => 55, a_high => 10, a_low => 5 }
    ));
    is $result-true, 10, 'When condition false, get implicit end return value';
    my $result-false = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 35 },
        technical => { standard_milk_yield => 45, a_high => 10, a_low => 5 }
    ));
    is $result-false, 5, 'When condition true, get early return value';
}, 'Early return from within a conditional';

subtest {
    my $f = parse-formula('return;');
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new());
    nok $result.defined, 'Correct result from evaluation';
}, 'Empty return evalutes to Nil';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        (In(solid_digestate) - Tech(er_solid_digestate)) /
        (In(compost) - Tech(er_compost));
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('solid_digestate', 'compost',),
        'Correct inputs-used';
    is-deeply $f.technical-used, ('er_solid_digestate', 'er_compost'),
        'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { solid_digestate => 100, compost => 13 },
        technical => { er_solid_digestate => 10, er_compost => 4 }
    ));
    is $result, (100 - 10) / (13 - 4), 'Correct result from evaluation';
}, 'Grouping parentheses and the - and / operators';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        # leading comment
        In(solid_digestate) * Tech(er_solid_digestate) # +
        #In(compost) * Tech(er_compost);
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('solid_digestate',),
        'Correct inputs-used';
    is-deeply $f.technical-used, ('er_solid_digestate',),
        'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { solid_digestate => 3 },
        technical => { er_solid_digestate => 10 }
    ));
    is $result, 3 * 10, 'Correct result from evaluation';
}, 'Comments';

subtest {
    my $f = parse-formula(q:to/FORMULA/);
        Sum(n_sol_excretion,Livestock::OtherCattle::Excretion )
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    my @output-used = $f.output-used;
    is @output-used.elems, 1, 'Have 1 output used';
    is @output-used[0].module, 'Livestock::OtherCattle::Excretion',
        'Correct output used module';
    is @output-used[0].symbol, 'n_sol_excretion',
        'Correct output used symbol';
    my @values = 9, 3, 27, 4;
    my $result = $f.evaluate(Agrammon::Environment.new(
        output => {
            'Livestock::OtherCattle::Excretion' => {
                'n_sol_excretion' => @values
            }
        }
    ));
    is $result, ([+] @values), 'Correct result from evaluation';
}, 'Sum(...)';

done-testing;
