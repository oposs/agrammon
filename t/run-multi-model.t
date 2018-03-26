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
    my %outputs = $model.run(:$input).get-outputs-hash();
    ok %outputs<Test::SubModule>:exists, 'Have outputs hash for Test::SubModule';
    is-deeply [%outputs<Test::SubModule>.sort(*.key)],
        [
            'Monkey A' => { 'Test::SubModule' => { sub_result => 20 * 42 } },
            'Monkey B' => { 'Test::SubModule' => { sub_result => 20 * 15 } },
            'Monkey C' => { 'Test::SubModule' => { sub_result => 20 * 98 } },
        ],
        'Correct multi-instance module results';
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
            }).get-outputs-hash();
    ok %outputs<Test::SubModule>:exists, 'Have outputs hash for Test::SubModule';
    is-deeply [%outputs<Test::SubModule>.sort(*.key)],
        [
            'Monkey A' => { 'Test::SubModule' => { sub_result => 10 * 42 } },
            'Monkey B' => { 'Test::SubModule' => { sub_result => 10 * 15 } },
            'Monkey C' => { 'Test::SubModule' => { sub_result => 10 * 98 } },
        ],
        'Correct multi-instance module results';
    ok %outputs<Test>:exists, 'Have outputs hash for Test';
    is %outputs<Test><result>, 90 * (10 * 42 + 10 * 15 + 10 * 98) + 10,
            'Correct result';
}

subtest 'Run with no instances' => {
    my $input = Agrammon::Inputs.new;
    $input.add-single-input('Test', 'final_add', 10);
    my %outputs = $model.run(:$input).get-outputs-hash();
    is-deeply %outputs<Test::SubModule>, [], 'Correct, empty, array of multi-instance outputs';
    ok %outputs<Test>:exists, 'Have outputs hash for Test';
    is %outputs<Test><result>, 10, 'Correct result';
}

done-testing;
