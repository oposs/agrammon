use v6;
use Agrammon::Inputs;
use Agrammon::Model;
use Test;

my $path = $*PROGRAM.parent.add('test-data/Models/run-test-no-multi');
my $model = Agrammon::Model.new(:$path);
$model.load('Test');

subtest 'Run without overriding any technical values' => {
    my $input = Agrammon::Inputs.new;
    $input.add-single-input('Test::SubModule', 'monkeys', 42);
    $input.add-single-input('Test', 'final_add', 10);
    my %outputs = $model.run(:$input).get-outputs-hash();
    ok %outputs<Test::SubModule>:exists, 'Have outputs hash for Test::SubModule';
    is %outputs<Test::SubModule><sub_result>, 20 * 42,
        'Correct sub_result';
    ok %outputs<Test>:exists, 'Have outputs hash for Test';
    is %outputs<Test><result>, 100 * (20 * 42) + 10,
        'Correct result';
}

subtest 'Run with technical values overrides' => {
    my $input = Agrammon::Inputs.new;
    $input.add-single-input('Test::SubModule', 'monkeys', 42);
    $input.add-single-input('Test', 'final_add', 10);
    my %outputs = $model.run(
        :$input,
        technical => {
            'Test::SubModule' => {
                sub_multiply => 10
            },
            'Test' => {
                final_multiply => 90
            }
        }).get-outputs-hash();
    ok %outputs<Test::SubModule>:exists, 'Have outputs hash for Test::SubModule';
    is %outputs<Test::SubModule><sub_result>, 10 * 42,
        'Correct sub_result';
    ok %outputs<Test>:exists, 'Have outputs hash for Test';
    is %outputs<Test><result>, 90 * (10 * 42) + 10,
        'Correct result';
}

subtest 'Run with missing input, which should use default calculation value' => {
    my $input = Agrammon::Inputs.new;
    $input.add-single-input('Test', 'final_add', 10);
    my %outputs = $model.run(:$input).get-outputs-hash();
    ok %outputs<Test::SubModule>:exists, 'Have outputs hash for Test::SubModule';
    is %outputs<Test::SubModule><sub_result>, 20 * 5,
            'Correct sub_result';
    ok %outputs<Test>:exists, 'Have outputs hash for Test';
    is %outputs<Test><result>, 100 * (20 * 5) + 10,
            'Correct result';
}

done-testing;
