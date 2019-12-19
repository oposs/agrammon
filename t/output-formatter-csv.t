use Agrammon::Model;
use Agrammon::OutputFormatter::CSV;
use Test;

my $test-simulation-name = '2010v2.1_20120425';
my $test-dataset-id = '2648';

my $path = $*PROGRAM.parent.add('test-data/Models/run-test-multi-deep');
my $model = Agrammon::Model.new(:$path);
$model.load('Test');

my $outputs = Agrammon::Outputs.new;
$outputs.add-output('Test', 'result', 142);
$outputs.declare-multi-instance('Test::SubModule');
given $outputs.new-instance('Test::SubModule', 'Monkey A') {
    .add-output('Test::SubModule', 'sub_result', 20);
    .add-output('Test::SubModule::SubTest', 'kids', 5);
}
given $outputs.new-instance('Test::SubModule', 'Monkey B') {
    .add-output('Test::SubModule', 'sub_result', 30);
    .add-output('Test::SubModule::SubTest', 'kids', 10);
}
given $outputs.new-instance('Test::SubModule', 'Monkey C') {
    .add-output('Test::SubModule', 'sub_result', 40);
    .add-output('Test::SubModule::SubTest', 'kids', 15);
}

my $csv = output-as-csv($test-simulation-name, $test-dataset-id, $model, $outputs, "en");
$csv = $csv.split(/^^/).sort.join;
is $csv, q:to/OUTPUT/, 'Correctly formed CSV output';
    2010v2.1_20120425;2648;Test::SubModule[Monkey A]::SubTest;kids;5;monkey kids
    2010v2.1_20120425;2648;Test::SubModule[Monkey A];sub_result;20;monkeys/hour
    2010v2.1_20120425;2648;Test::SubModule[Monkey B]::SubTest;kids;10;monkey kids
    2010v2.1_20120425;2648;Test::SubModule[Monkey B];sub_result;30;monkeys/hour
    2010v2.1_20120425;2648;Test::SubModule[Monkey C]::SubTest;kids;15;monkey kids
    2010v2.1_20120425;2648;Test::SubModule[Monkey C];sub_result;40;monkeys/hour
    2010v2.1_20120425;2648;Test;result;142;monkeys/hour
    OUTPUT

done-testing;
