use v6;
use Agrammon::Model;
use Test;

my $path = $*PROGRAM.parent.add('test-data/Models/run-test-no-multi');
my $model = Agrammon::Model.new(path => $path);
$model.load('Test');

{
    my %outputs = $model.run(inputs => {
        'Test::SubModule' => {
            monkeys => 42
        },
        'Test' => {
            final_add => 10
        }
    });
    ok %outputs<Test::SubModule>:exists, 'Have outputs hash for Test::SubModule';
    is %outputs<Test::SubModule><sub_result>, 20 * 42,
        'Correct sub_result';
    ok %outputs<Test>:exists, 'Have outputs hash for Test';
    is %outputs<Test><result>, 100 * (20 * 42) + 10,
        'Correct result';
}

done-testing;
