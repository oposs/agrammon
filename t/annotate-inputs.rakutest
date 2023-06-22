use v6;
use Agrammon::Inputs;
use Agrammon::Model;
use Test;

my $path = $*PROGRAM.parent.add('test-data/Models/run-test-multi-deep');
my $model = Agrammon::Model.new(:$path);
$model.load('Test');

# Set up a bunch of inputs.
my $input = Agrammon::Inputs.new;
$input.add-multi-input('Test::SubModule', 'Monkey A', '', 'monkeys', 42);
$input.add-multi-input('Test::SubModule', 'Monkey B', '', 'monkeys', 15);
$input.add-multi-input('Test::SubModule', 'Monkey C', '', 'monkeys', 98);
$input.add-multi-input('Test::SubModule', 'Monkey A', 'SubTest', 'kids', 5);
$input.add-multi-input('Test::SubModule', 'Monkey B', 'SubTest', 'kids', 3);
$input.add-multi-input('Test::SubModule', 'Monkey C', 'SubTest', 'kids', 7);
$input.add-single-input('Test', 'final_add', 10);

# Obtain and check annotated inputs.
my @annotated = $model.annotate-inputs($input);
is @annotated.elems, 7, 'Got 7 annotated inputs';
given @annotated[0] {
    is-deeply .module, $model.get-module('Test::SubModule::SubTest'),
            'Correct module in first annotated result';
    is-deeply .input, $model.get-input('Test::SubModule::SubTest', 'kids'),
            'Correct input in first annotated result';
    is-deeply .instance-id, 'Monkey A',
            'Correct instance ID in first annotated result';
    is-deeply .value, 5,
            'Correct value in first annotated result';
}
given @annotated[1] {
    is-deeply .module, $model.get-module('Test::SubModule'),
            'Correct module in second annotated result';
    is-deeply .input, $model.get-input('Test::SubModule', 'monkeys'),
            'Correct input in second annotated result';
    is-deeply .instance-id, 'Monkey A',
            'Correct instance ID in second annotated result';
    is-deeply .value, 42,
            'Correct value in second annotated result';
}
given @annotated[*-1] {
    is-deeply .module, $model.get-module('Test'),
            'Correct module in final annot ated result';
    is-deeply .input, $model.get-input('Test', 'final_add'),
            'Correct input in final annotated result';
    is-deeply .instance-id, Str,
            'No instance ID in final annotated result';
    is-deeply .value, 10,
            'Correct value in final annotated result';
}

done-testing;
