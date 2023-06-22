use Agrammon::Model;
use Test;

my $path = $*PROGRAM.parent.add('test-data/Models/defaults');
my $model = Agrammon::Model.new(:$path);
$model.load('Top');

my $input = Agrammon::Inputs.new;
$input.add-single-input('Top', 'input1', 42);
$input.add-multi-input('Sub', 'Instance1', '', 'input1', 10);
$input.add-multi-input('Sub', 'Instance2', '', 'input1', 20);
lives-ok { $input.apply-defaults($model, {}) },
        'Can apply defaults to inputs when there are formulas';

my %outputs = $model.run(:$input).get-outputs-hash();

subtest 'Single instance module with input defaults' => {
    given %outputs<Top> {
        is .<output1>, 42, 'Directly provided input works';
        is .<output2>, 84, 'Input default calculated from another input works';
        is .<output3>, 215, 'Input calculated from a technical works';
        is .<output4>, 42, 'Input default number works';
        is .<output5>, 'orangs', 'Input default enum works';
    }
}

subtest 'Multi instance module with input defaults' => {
    given %outputs<Sub>.first(*.key eq 'Instance1').value<Sub> {
        is .<output1>, 10, 'Directly provided input works (instance 1)';
        is .<output2>, 50, 'Input default calculated from another input works (instance 1)';
    }
    given %outputs<Sub>.first(*.key eq 'Instance2').value<Sub> {
        is .<output1>, 20, 'Directly provided input works (instance 1)';
        is .<output2>, 100, 'Input default calculated from another input works (instance 1)';
    }
}

done-testing;
