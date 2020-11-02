use v6;
use Agrammon::Formula;
use Agrammon::ModuleBuilder;
use Agrammon::ModuleParser;
use Test;

my $test-root   = $*PROGRAM.parent.add('test-data');
for "$test-root/CMilk.nhd", "$test-root/CMilk-crazy-ws.nhd" -> $module-file {
    subtest "Loading $module-file" => {
        my $parsed = Agrammon::ModuleParser.parsefile(
            $module-file,
            actions => Agrammon::ModuleBuilder.new
        );
        ok $parsed, "Successfully parsed $module-file";

        my $model = $parsed.ast;
        isa-ok $model, Agrammon::Model::Module, 'Parsing results in a Module';
        is $model.author, 'Agrammon Group', 'Correct author';
        is $model.date, '2008-02-29', 'Correct date';
        is $model.taxonomy, 'Livestock::DairyCow::Excretion::CMilk', 'Correct taxonomy';
        is $model.short, q:to/SHORT/.trim-trailing, 'Correct short';
            Just a short descritption
            But maybe may lines
            SHORT
        is $model.description, q:to/DESC/.trim-trailing, 'Correct description';
            Longer description. May span many lines.
            Longer description. May span many lines.
            Longer description. May span many lines.
            DESC

        my @input = $model.input;
        is @input.elems, 1, 'Have 1 input';
        isa-ok @input[0], Agrammon::Model::Input, 'Correct input model type';
        given @input[0] {
            is .name, 'milk_yield', 'Correct input name';
            is .default-calc, 6000, 'Correct default-calc value';
            # TODO Test type once we decide how to represent it
            # TODO Test validator once we decide how to represent it
            is .labels.elems, 3, 'Have 3 input labels';
            is .labels.keys.sort, <de en fr>, 'Correct label keys';
            is .labels<en>, 'Milk yield per dairy cow', 'Correct label value';
            is .units.elems, 3, 'Have 3 input units';
            is .units.keys.sort, <de en fr>, 'Correct unit keys';
            is .units<de>, 'kg/Jahr', 'Correct unit value';
            is .description, 'Annual milk yield per dairy cow.',
                'Correct input description';
            is .help.elems, 3, 'Have 3 input help texts';
            is .help.keys.sort, <de en fr>, 'Correct help keys';
            is .help<fr>, '<p>Proposition de valeur standard: 6500 kg par an </p>',
                'Correct help value';
            nok .is-branch, 'This is not a branch input';
        }

        my @technical = $model.technical;
        is @technical.elems, 3, 'Have 3 technicals';
        for ^3 {
            isa-ok @technical[$_], Agrammon::Model::Technical,
                'Correct technical model type';
        }
        is @technical.map(*.name), <standard_milk_yield a_high a_low>,
            'Correct names of technical section entries';
        given @technical[0] {
            is .name, 'standard_milk_yield', 'Correct name of first technical';
            is .value, 6500, 'Correct value of first technical';
            is .description, 'Annual standard milk yield per dairy cow.',
                'Correct description for first technical';
            is .units.elems, 3, 'First technical has 3 units';
            is .units.keys.sort, <de en fr>, 'Correct unit keys';
            is .units<de>, 'kg/Jahr', 'Correct unit value';
        }
        given @technical[2] {
            is .name, 'a_low', 'Correct name of third technical';
            is .value, 0.1, 'Correct value of third technical';
            is .description, 'For milk yield < 6500',
                'Correct description for third technical';
            is .units.elems, 1, 'Third technical has 1 unit';
            is .units.keys, <en>, 'Correct unit key';
            is .units<en>, '-', 'Correct unit value';
        }

        my @output = $model.output;
        is @output.elems, 1, 'Have one output';
        isa-ok @output[0], Agrammon::Model::Output,
            'Correct output model type';
        given @output[0] {
            is .name, 'cmilk_yield', 'Correct name of output';
            is .print, 15, 'Correct print of output';
            is .description, 'Milk yield correction factor for annual N excretion.',
                'Correct description for output';
            is .units.elems, 1, 'First output has 1 unit';
            is .units.keys, <en>, 'Correct unit key';
            is .units<en>, '-', 'Correct unit value';
            ok .formula ~~ Agrammon::Formula, 'Formula parsed into a Formula object';
        }
    }
}

my $module-file = "$test-root/CMilkWithTests.nhd";
subtest "Loading $module-file" => {
    my $parsed = Agrammon::ModuleParser.parsefile(
        $module-file,
        actions => Agrammon::ModuleBuilder.new
    );
    ok $parsed, "Successfully parsed $module-file";

    my $model = $parsed.ast;
    isa-ok $model, Agrammon::Model::Module, 'Parsing results in a Module';

    # just testing additiona tests section
    my @tests = $model.tests;
    is @tests.elems, 1, 'Have one test';
    isa-ok @tests[0], Agrammon::Model::Test,
        'Correct tests model type';
    given @tests[0] {
        is .name, 'test1', 'Correct name of test';
        is .description, 'Test1',
            'Correct description for test';
    }
}

$module-file = "$test-root/PlantProduction.nhd";
subtest "Loading $module-file" => {
    my $parsed = Agrammon::ModuleParser.parsefile(
        $module-file,
        actions => Agrammon::ModuleBuilder.new
    );
    ok $parsed, "Successfully parsed $module-file";

    my $model = $parsed.ast;
    isa-ok $model, Agrammon::Model::Module, 'Parsing results in a Module';

    my @external = $model.external;
    is @external.elems, 3, 'Found 3 externals';
    for ^3 {
        isa-ok @external[0], Agrammon::Model::External,
            'External entry is correct model type';
    }
    is @external[0].name, 'PlantProduction::AgriculturalArea',
        'Correct external name (1)';
    is @external[1].name, 'PlantProduction::MineralFertiliser',
        'Correct external name (2)';
    is @external[2].name, 'PlantProduction::RecyclingFertiliser',
        'Correct external name (3)';
}

$module-file = "$test-root/DairyCow.nhd";
subtest "Loading $module-file" => {
    my $parsed = Agrammon::ModuleParser.parsefile(
        $module-file,
        actions => Agrammon::ModuleBuilder.new
    );
    ok $parsed, "Successfully parsed $module-file";

    my $model = $parsed.ast;
    isa-ok $model, Agrammon::Model::Module, 'Parsing results in a Module';
    ok $model.instances eq 'multi', 'DairyCow.nhd is multi';
    ok $model.gui eq 'Livestock::DairyCow,Tierhaltung::Milchkühe,Production animale::Vaches latière,Livestock::Dairy cows', 'DairyCow.nhd has correct gui parameter';
}

$module-file = "$test-root/Models/hr-limit-2010/Livestock/Poultry/Excretion.nhd";
subtest "Loading $module-file" => {
    my $parsed = Agrammon::ModuleParser.parsefile(
        $module-file,
        actions => Agrammon::ModuleBuilder.new
    );
    ok $parsed, "Successfully parsed $module-file";
    my $model = $parsed.ast;
    isa-ok $model, Agrammon::Model::Module, 'Parsing results in a Module';
    nok $model.input[0].is-branch, 'First input is not a branch';
    ok $model.input[1].is-branch, 'First input is a branch';
}

done-testing;
