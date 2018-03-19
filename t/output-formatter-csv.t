use Agrammon::Model;
use Agrammon::OutputFormatter::CSV;
use Test;

my $test-simulation-name = '2010v2.1_20120425';
my $test-dataset-id = '2648';
my %outputs = 'Test' => { result => 42 }, 'Test::SubModule' => { sub_result => 101 };

my $path = $*PROGRAM.parent.add('test-data/Models/run-test-no-multi');
my $model = Agrammon::Model.new(path => $path);
$model.load('Test');

my $csv = output-as-csv($test-simulation-name, $test-dataset-id, $model, %outputs, "en");
$csv = $csv.split(/^^/).sort.join;
is $csv, q:to/OUTPUT/, 'Correctly formed CSV output';
    2010v2.1_20120425;2648;Test::SubModule;sub_result;101;monkeys/hour
    2010v2.1_20120425;2648;Test;result;42;monkeys/hour
    OUTPUT

done-testing;
