use v6;
use Agrammon::Environment;
use Agrammon::Formula;
use Agrammon::Formula::Parser;
use Test;

subtest {
    my $f = parse-formula('In(agricultural_area)', 'PlantProduction');
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
    my $f = parse-formula('In(agricultural_area);', 'PlantProduction');
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
    my $f = parse-formula('Tech(er_agricultural_area)', 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        Val(mineral_nitrogen_fertiliser_urea, PlantProduction);
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    my @output-used = $f.output-used;
    is @output-used.elems, 1, 'Have 1 output used';
    is @output-used[0].module, 'PlantProduction',
        'Correct output used module';
    is @output-used[0].symbol, 'mineral_nitrogen_fertiliser_urea',
        'Correct output used symbol';
    my $result = $f.evaluate(Agrammon::Environment.new(
        output => {
            'PlantProduction' => {
                'mineral_nitrogen_fertiliser_urea' => 45
            }
        }
    ));
    is $result, 45, 'Correct result from evaluation';
}, 'Val(...)';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'Livestock::DairyCow::Housing::Type');
        Val(dairy_cows, ..::Excretion);
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    my @output-used = $f.output-used;
    is @output-used.elems, 1, 'Have 1 output used';
    is @output-used[0].module, 'Livestock::DairyCow::Excretion',
        'Correct output used module';
    is @output-used[0].symbol, 'dairy_cows',
        'Correct output used symbol';
    my $result = $f.evaluate(Agrammon::Environment.new(
        output => {
            'Livestock::DairyCow::Excretion' => {
                'dairy_cows' => 49
            }
        }
    ));
    is $result, 49, 'Correct result from evaluation';
}, 'Val(...) with name using ..';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        Val(nh3_nmineralfertiliser, PlantProduction) +
        Val(nh3_nrecyclingfertiliser, PlantProduction::RecyclingFertiliser)
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    my @output-used = $f.output-used;
    is @output-used.elems, 2, 'Have 2 output used';
    is @output-used[0].module, 'PlantProduction',
        'Correct first output used module';
    is @output-used[0].symbol, 'nh3_nmineralfertiliser',
        'Correct first output used symbol';
    is @output-used[1].module, 'PlantProduction::RecyclingFertiliser',
        'Correct second output used module';
    is @output-used[1].symbol, 'nh3_nrecyclingfertiliser',
        'Correct second output used symbol';
    my $result = $f.evaluate(Agrammon::Environment.new(
        output => {
            'PlantProduction' => {
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        2.5 * In(compost) + 1.0
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('compost',), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { compost => 55 }
    ));
    is $result, 2.5 * 55 + 1.0, 'Correct result from evaluation';
}, 'Rational literals';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        "foo\nbar"
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new());
    is $result, "foo\nbar", 'Correct result from evaluation';
}, 'Double-quoted string literals';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        In(milk_yield) != Tech(standard_milk_yield)
            ? Tech(a_low)
            : Tech(a_high)
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
    is $result-true, 10, 'Correct result when condition is false';
    my $result-false = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 35 },
        technical => { standard_milk_yield => 45, a_high => 10, a_low => 5 }
    ));
    is $result-false, 5, 'Correct result when condition is true';
}, '... ? ... : ... construct';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        In(level) eq 'low'
            ? Tech(a_low)
            : Tech(a_high)
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('level',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('a_low', 'a_high'), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result-true = $f.evaluate(Agrammon::Environment.new(
        input => { level => 'low' },
        technical => { a_high => 10, a_low => 5 }
    ));
    is $result-true, 5, 'Correct result when eq matches';
    my $result-false = $f.evaluate(Agrammon::Environment.new(
        input => { level => 'high' },
        technical => { a_high => 10, a_low => 5 }
    ));
    is $result-false, 10, 'Correct result when eq does not match';
}, 'The string eq operator and string literals';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        In(level) ne 'low'
            ? Tech(a_high)
            : Tech(a_low)
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('level',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('a_high', 'a_low'), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result-true = $f.evaluate(Agrammon::Environment.new(
        input => { level => 'high' },
        technical => { a_high => 10, a_low => 5 }
    ));
    is $result-true, 10, 'Correct result when ne does not match';
    my $result-false = $f.evaluate(Agrammon::Environment.new(
        input => { level => 'low' },
        technical => { a_high => 10, a_low => 5 }
    ));
    is $result-false, 5, 'Correct result when ne matches';
}, 'The string ne operator and string literals';

subtest {
    my $f = parse-formula('return In(agricultural_area)', 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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
    my $f = parse-formula('return;', 'PlantProduction');
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new());
    nok $result.defined, 'Correct result from evaluation';
}, 'Empty return evalutes to Nil';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
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

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        Out(mineral_nitrogen_fertiliser_urea);
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    my @output-used = $f.output-used;
    is @output-used.elems, 1, 'Have 1 output used';
    is @output-used[0].module, 'PlantProduction',
        'Correct output used module';
    is @output-used[0].symbol, 'mineral_nitrogen_fertiliser_urea',
        'Correct output used symbol';
    my $result = $f.evaluate(Agrammon::Environment.new(
        output => {
            'PlantProduction' => {
                'mineral_nitrogen_fertiliser_urea' => 89
            }
        }
    ));
    is $result, 89, 'Correct result from evaluation';
}, 'Out(...)';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        given (In(level)) {
            return Tech(a_low) when 'low';
            return Tech(a_mid) when 'middle';
            return Tech(a_high) when 'high';
        }
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('level',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('a_low', 'a_mid', 'a_high'), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { level => 'low' },
        technical => { a_high => 20, a_mid => 10, a_low => 5 }
    ));
    is $result, 5, 'Correct result for first when';
    $result = $f.evaluate(Agrammon::Environment.new(
        input => { level => 'high' },
        technical => { a_high => 20, a_mid => 10, a_low => 5 }
    ));
    is $result, 20, 'Correct result for final when';
    $result = $f.evaluate(Agrammon::Environment.new(
        input => { level => 'middle' },
        technical => { a_high => 20, a_mid => 10, a_low => 5 }
    ));
    is $result, 10, 'Correct result for middle when';
}, 'The given block and statement modifier when';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        if (In(milk_yield) != 1 and In(milk_yield) != 2) {
            return 'yes';
        }
        else {
            return 'no'
        }
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('milk_yield',), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 1 }
    ));
    is $result, 'no', 'Correct result when false before and';
    $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 2 }
    ));
    is $result, 'no', 'Correct result when false after and';
    $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 3 }
    ));
    is $result, 'yes', 'Correct result when both true';
}, 'The infix and operator';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        if (In(milk_yield) == 1 or In(milk_yield) == 2) {
            return 'yes';
        }
        else {
            return 'no'
        }
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('milk_yield',), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 1 }
    ));
    is $result, 'yes', 'Correct result when true before or';
    $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 2 }
    ));
    is $result, 'yes', 'Correct result when true after or';
    $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 3 }
    ));
    is $result, 'no', 'Correct result when both false';
}, 'The infix or operator';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        if (In(milk_yield) != 1 && In(milk_yield) != 2) {
            return 'yes';
        }
        else {
            return 'no'
        }
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('milk_yield',), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 1 }
    ));
    is $result, 'no', 'Correct result when false before and';
    $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 2 }
    ));
    is $result, 'no', 'Correct result when false after and';
    $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 3 }
    ));
    is $result, 'yes', 'Correct result when both true';
}, 'The infix && operator';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        if (In(milk_yield) == 1 || In(milk_yield) == 2) {
            return 'yes';
        }
        else {
            return 'no'
        }
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('milk_yield',), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 1 }
    ));
    is $result, 'yes', 'Correct result when true before or';
    $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 2 }
    ));
    is $result, 'yes', 'Correct result when true after or';
    $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 3 }
    ));
    is $result, 'no', 'Correct result when both false';
}, 'The infix || operator';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        defined In(milk_yield) ? 'yes' : 'nope'
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('milk_yield',), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => 55 }
    ));
    is $result, "yes", 'Correct result from defined when value is defined';
    $result = $f.evaluate(Agrammon::Environment.new(
        input => { milk_yield => Nil }
    ));
    is $result, "nope", 'Correct result from defined when value is not defined';
}, 'defined <term>';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        foo()
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, (), 'Correct inputs-used';
    is-deeply $f.technical-used, (), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $calls = 0;
    my $result = $f.evaluate(Agrammon::Environment.new(
        builtins => { foo => sub { $calls++; return 42 } }
    ));
    is $calls, 1, 'Built-in function was called';
    is $result, "42", 'Result is return value of built-in function';
}, 'Call a simple built-in function without arguments';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        bar(In(n), Tech(s))
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('n',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('s',), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my @args;
    my $result = $f.evaluate(Agrammon::Environment.new(
        builtins => { bar => sub ($x, $str) { push @args, ($x, $str); return $str x $x } },
        input => { n => 3 },
        technical => { s => 'foo' }
    ));
    is @args.elems, 1, 'Built-in function was called';
    is @args[0][0], 3, 'Correct first argument';
    is @args[0][1], 'foo', 'Correct second argument';
    is $result, "foofoofoo", 'Result is return value of built-in function';
}, 'Call a simple built-in function with arguments In(...)/Tech(...) arguments';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        writeLog({
            en => 'hello',
            de => In(de),
            fr => Tech(fr)
        });
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('de',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('fr',), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my @args;
    my $result = $f.evaluate(Agrammon::Environment.new(
        builtins => { writeLog => sub (%h) { push @args, %h; return 'logged' } },
        input => { de => 'hallo' },
        technical => { fr => 'salut' }
    ));
    is @args.elems, 1, 'Built-in function was called once';
    is-deeply @args[0], { en => 'hello', de => 'hallo', fr => 'salut' },
        'Correct hash passed as argument';
    is $result, "logged", 'Result is return value of built-in function';
}, 'Call a simple built-in function with a hash argument';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        return Tech(fr) if In(de) eq 'hallo';
        return 'bonjour';
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('de',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('fr',), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result-true = $f.evaluate(Agrammon::Environment.new(
        input => { de => 'hallo' },
        technical => { fr => 'salut' }
    ));
    is $result-true, "salut", 'Correct result when if is true';
    my $result-false = $f.evaluate(Agrammon::Environment.new(
        input => { de => 'guten tag' },
        technical => { fr => 'salut' }
    ));
    is $result-false, "bonjour", 'Correct result when if is false';
}, 'Statement modifier if';

subtest {
    my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
        return Tech(fr) unless In(de) eq 'guten tag';
        return 'bonjour';
        FORMULA
    ok $f ~~ Agrammon::Formula, 'Get something doing Agrammon::Formula from parse';
    is-deeply $f.input-used, ('de',), 'Correct inputs-used';
    is-deeply $f.technical-used, ('fr',), 'Correct technical-used';
    is-deeply $f.output-used, (), 'Correct output-used';
    my $result-true = $f.evaluate(Agrammon::Environment.new(
        input => { de => 'guten tag' },
        technical => { fr => 'salut' }
    ));
    is $result-true, "bonjour", 'Correct result when unless is true';
    my $result-false = $f.evaluate(Agrammon::Environment.new(
        input => { de => 'hallo' },
        technical => { fr => 'salut' }
    ));
    is $result-false, "salut", 'Correct result when unless is false';
}, 'Statement modifier unless';

done-testing;
