use v6;
use Agrammon::Inputs;
use Agrammon::Model;
use Test;

my $path = $*PROGRAM.parent.add('test-data/Models/run-test-multi-deep');
my $model = Agrammon::Model.new(path => $path);
$model.load('Test');

subtest 'Run without overriding any technical values' => {
    my $input = Agrammon::Inputs.new;
    $input.add-multi-input('Test::SubModule', 'Monkey A', '',        'monkeys', 42);
    $input.add-multi-input('Test::SubModule', 'Monkey B', '',        'monkeys', 15);
    $input.add-multi-input('Test::SubModule', 'Monkey C', '',        'monkeys', 98);
    $input.add-multi-input('Test::SubModule', 'Monkey A', 'SubTest', 'kids',     5);
    $input.add-multi-input('Test::SubModule', 'Monkey B', 'SubTest', 'kids',     3);
    $input.add-multi-input('Test::SubModule', 'Monkey C', 'SubTest', 'kids',     7);
    $input.add-single-input('Test', 'final_add', 10);
    my %outputs = $model.run(:$input);
    dd %outputs;
    ok %outputs<Test::SubModule::SubTest>:exists, 'Have outputs hash for Test::SubModule::SubTest';
    is %outputs<Test::SubModule::SubTest><kids>, [5, 3, 7], 'Correct kids array';
    ok %outputs<Test::SubModule>:exists, 'Have outputs hash for Test::SubModule';
    is %outputs<Test::SubModule><sub_result>, [20 * (42+5), 20 * (15+3), 20 * (98+7)],
            'Correct sub_result array';
    ok %outputs<Test>:exists, 'Have outputs hash for Test';
    is %outputs<Test><result>, 100 * (20 * (42+5) + 20 * (15+3) + 20 * (98+7)) + 10,
            'Correct result';
}

done-testing;
