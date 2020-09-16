use Agrammon::Model;
use Agrammon::OutputFormatter::GUI;
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

# TODO
todo "Not implemented yet";
flunk "gui output formatter tests";

done-testing;
