use v6;
use Agrammon::Inputs;
use Test;

subtest 'Single-instance modules', {
    my $ai = Agrammon::Inputs.new;
    is-deeply $ai.input-hash-for('Foo::Bar'), {},
        'Asking for single-instance input hash when no values returns empty hash';

    $ai.add-single-input('Foo::Bar', 'answer', 42);
    $ai.add-single-input('Foo', 'steak', 'beef');
    $ai.add-single-input('Foo::Bar', 'beer', 'Yeti');
    $ai.add-single-input('Foo', 'potato', 'fried');
    is-deeply $ai.input-hash-for('Foo'),
        { steak => 'beef', potato => 'fried' },
        'Inputs correctly collected for module Foo';
    is-deeply $ai.input-hash-for('Foo::Bar'),
        { answer => 42, beer => 'Yeti' },
        'Inputs correctly collected for module Foo::Bar';
}

subtest 'Multi-instance modules', {
    my $ai = Agrammon::Inputs.new;
    is-deeply $ai.inputs-list-for('Foo::Bar'), [],
        'Asking for multi-instance input list when no values returns empty array';

    $ai.add-multi-input('Foo::Bar', 'Cow 1', '', 'age', 10);
    $ai.add-multi-input('Foo::Bar', 'Cow 1', '', 'weight', 200);
    $ai.add-multi-input('Foo::Bar', 'Cow 1', 'Excretion', 'kilos', 20);
    $ai.add-multi-input('Foo::Bar', 'Cow 1', 'Excretion', 'smell', 'awful');
    $ai.add-multi-input('Foo::Bar', 'Cow 2', '', 'age', 6);
    $ai.add-multi-input('Foo::Bar', 'Cow 2', '', 'weight', 199);
    $ai.add-multi-input('Foo::Bar', 'Cow 2', 'Excretion', 'kilos', 19);
    $ai.add-multi-input('Foo::Bar', 'Cow 2', 'Excretion', 'smell', 'putrid');
    my @inputs = $ai.inputs-list-for('Foo::Bar');
    is @inputs.elems, 2, 'Can fetch list of inputs for a multi module';
    isa-ok @inputs[0], Agrammon::Inputs, 'First input is Agrammon::Inputs instance';
    isa-ok @inputs[1], Agrammon::Inputs, 'Second input is Agrammon::Inputs instance';
    is-deeply @inputs[0].input-hash-for('Foo::Bar'),
        { age => 10, weight => 200 },
        'Correct module input for first multi input';
    is-deeply @inputs[0].input-hash-for('Foo::Bar::Excretion'),
        { kilos => 20, smell => 'awful' },
        'Correct dependent module input for first multi input';
    is-deeply @inputs[1].input-hash-for('Foo::Bar'),
        { age => 6, weight => 199 },
        'Correct module input for second multi input';
    is-deeply @inputs[1].input-hash-for('Foo::Bar::Excretion'),
        { kilos => 19, smell => 'putrid' },
        'Correct dependent module input for first multi input';
}

subtest 'Cannot add multi input for taxonomy that has single input', {
    my $ai = Agrammon::Inputs.new;
    $ai.add-single-input('Foo::Bar', 'answer', 42);
    throws-like
        { $ai.add-multi-input('Foo::Bar', 'Cow 1', '', 'age', 10) },
        X::Agrammon::Inputs::AlreadySingle,
        taxonomy => 'Foo::Bar';
}

subtest 'Cannot add single input for taxonomy that has multi input', {
    my $ai = Agrammon::Inputs.new;
    $ai.add-multi-input('Foo::Bar', 'Cow 1', '', 'age', 10);
    throws-like
        { $ai.add-single-input('Foo::Bar', 'answer', 42) },
        X::Agrammon::Inputs::AlreadyMulti,
        taxonomy => 'Foo::Bar';
}

subtest 'Cannot get single input from multi taxonomy', {
    my $ai = Agrammon::Inputs.new;
    $ai.add-single-input('Foo::Bar', 'answer', 42);
    throws-like
        { $ai.inputs-list-for('Foo::Bar') },
        X::Agrammon::Inputs::Single,
        taxonomy => 'Foo::Bar';
}

subtest 'Cannot get multi input from single taxonomy', {
    my $ai = Agrammon::Inputs.new;
    $ai.add-multi-input('Foo::Bar', 'Cow 1', '', 'age', 10);
    throws-like
        { $ai.input-hash-for('Foo::Bar') },
        X::Agrammon::Inputs::Multi,
        taxonomy => 'Foo::Bar';
}

done-testing;
