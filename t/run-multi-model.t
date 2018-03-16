use v6;
use Agrammon::Inputs;
use Agrammon::Model;
use Test;

my $path = $*PROGRAM.parent.add('test-data/Models/run-test-multi');
my $model = Agrammon::Model.new(path => $path);
$model.load('Test');

subtest 'Run without overriding any technical values' => {
    my $input = Agrammon::Inputs.new;
    $input.add-multi-input('Test::SubModule', 'Monkey A', '', 'monkeys', 42);
    $input.add-multi-input('Test::SubModule', 'Monkey B', '', 'monkeys', 15);
    $input.add-multi-input('Test::SubModule', 'Monkey C', '', 'monkeys', 98);
    $input.add-single-input('Test', 'final_add', 10);
    my %outputs = $model.run(:$input);
    ok %outputs<Test::SubModule>:exists, 'Have outputs hash for Test::SubModule';
    is %outputs<Test::SubModule><sub_result>, [20 * 42, 20 * 15, 20 * 98],
            'Correct sub_result array';
    ok %outputs<Test>:exists, 'Have outputs hash for Test';
    is %outputs<Test><result>, 100 * (20 * 42 + 20 * 15 + 20 * 98) + 10,
            'Correct result';
}

subtest 'Run with technical values overrides' => {
    my $input = Agrammon::Inputs.new;
    $input.add-multi-input('Test::SubModule', 'Monkey A', '', 'monkeys', 42);
    $input.add-multi-input('Test::SubModule', 'Monkey B', '', 'monkeys', 15);
    $input.add-multi-input('Test::SubModule', 'Monkey C', '', 'monkeys', 98);
    $input.add-single-input('Test', 'final_add', 10);
    my %outputs = $model.run(:$input,
            technical => {
                'Test::SubModule' => {
                    sub_multiply => 10
                },
                'Test' => {
                    final_multiply => 90
                }
            });
    ok %outputs<Test::SubModule>:exists, 'Have outputs hash for Test::SubModule';
    is %outputs<Test::SubModule><sub_result>, [10 * 42, 10 * 15, 10 * 98],
            'Correct sub_result array';
    ok %outputs<Test>:exists, 'Have outputs hash for Test';
    is %outputs<Test><result>, 90 * (10 * 42 + 10 * 15 + 10 * 98) + 10,
            'Correct result';
}

subtest 'Run with no instances' => {
    my $input = Agrammon::Inputs.new;
    $input.add-single-input('Test', 'final_add', 10);
    my %outputs = $model.run(:$input);
    ok %outputs<Test::SubModule>:exists, 'Have outputs hash for Test::SubModule';
    is %outputs<Test::SubModule><sub_result>, [], 'Correct,empty, sub_result array';
    ok %outputs<Test>:exists, 'Have outputs hash for Test';
    is %outputs<Test><result>, 10, 'Correct result';
}

done-testing;
