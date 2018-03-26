use Agrammon::Outputs;
use Test;

subtest 'Simple outputs, no instances' => {
    my $outputs = Agrammon::Outputs.new;
    $outputs.add-output('Foo::Bar', 'baz', 42);
    $outputs.add-output('Foo::Bar', 'wat', 101);
    $outputs.add-output('Woo::Baz', 'ugg', 'boots');
    is $outputs.get-output('Foo::Bar', 'baz'), 42, 'Can get output (1)';
    is $outputs.get-output('Foo::Bar', 'wat'), 101, 'Can get output (2)';
    is $outputs.get-output('Woo::Baz', 'ugg'), 'boots', 'Can get output (3)';
    throws-like { $outputs.get-output('Woo::Baz', 'ugh') },
        X::Agrammon::Outputs::Unset,
        module => 'Woo::Baz',
        name => 'ugh';
    is-deeply $outputs.get-outputs-hash(),
        { 'Foo::Bar' => { baz => 42, wat => 101 }, 'Woo::Baz' => { ugg => 'boots' } },
        'Getting single-instance outputs works';
}

subtest 'Multi-instance outputs' => {
    my $outputs = Agrammon::Outputs.new;
    $outputs.add-output('Visible::From::All', 'sym', 99);

    throws-like { $outputs.new-instance('Multi::Instance', 'Instance 1') },
        X::Agrammon::Outputs::NotDeclaredMultiInstance,
        module => 'Multi::Instance';
    $outputs.declare-multi-instance('Multi::Instance');
    my $instance-a = $outputs.new-instance('Multi::Instance', 'Instance 1');
    $instance-a.add-output('Multi::Instance::Foo', 'bar', 10);
    $instance-a.add-output('Multi::Instance::Bar', 'baz', 20);
    $instance-a.add-output('Multi::Instance', 'wat', 30);
    is $instance-a.get-output('Multi::Instance::Foo', 'bar'), 10, 'Can get output from first instance (1)';
    is $instance-a.get-output('Multi::Instance::Bar', 'baz'), 20, 'Can get output from first instance (2)';
    is $instance-a.get-output('Multi::Instance', 'wat'), 30, 'Can get output from first instance (3)';
    is $instance-a.get-output('Visible::From::All', 'sym'), 99,
        'Can access symbol from first instance from an outer single-instance module';
    throws-like { $instance-a.get-output('Woo::Baz', 'ugh') },
        X::Agrammon::Outputs::Unset,
        module => 'Woo::Baz',
        name => 'ugh';

    throws-like { $outputs.new-instance('Multi::Instance', 'Instance 1') },
        X::Agrammon::Outputs::DuplicateInstance,
        taxonomy-prefix => 'Multi::Instance',
        instance-name => 'Instance 1',
        'Cannot add duplicate instances';

    my $instance-b = $outputs.new-instance('Multi::Instance', 'Instance 2');
    throws-like { $instance-b.get-output('Multi::Instance', 'wat') },
        X::Agrammon::Outputs::Unset,
        module => 'Multi::Instance',
        name => 'wat',
        'No leakage of symbols between instances';
    $instance-b.add-output('Multi::Instance::Foo', 'bar', 50);
    $instance-b.add-output('Multi::Instance::Bar', 'baz', 60);
    $instance-b.add-output('Multi::Instance', 'wat', 70);
    is $instance-b.get-output('Multi::Instance::Foo', 'bar'), 50, 'Can get output from second instance (1)';
    is $instance-b.get-output('Multi::Instance::Bar', 'baz'), 60, 'Can get output from second instance (2)';
    is $instance-b.get-output('Multi::Instance', 'wat'), 70, 'Can get output from second instance (3)';
    is $instance-b.get-output('Visible::From::All', 'sym'), 99,
        'Can access symbol from first instance from an outer single-instance module';

    is $outputs.get-sum('Multi::Instance::Foo', 'bar'), 10 + 50, 'Can get sum of multi-instance outputs (1)';
    is $outputs.get-sum('Multi::Instance::Bar', 'baz'), 20 + 60, 'Can get sum of multi-instance outputs (2)';
    is $outputs.get-sum('Multi::Instance', 'wat'), 30 + 70, 'Can get sum of multi-instance outputs (3)';

    throws-like { $outputs.get-output('Multi::Instance::Foo', 'bar') },
        X::Agrammon::Outputs::IsMultiInstance,
        module => 'Multi::Instance::Foo',
        name => 'bar';
    throws-like { $outputs.get-sum('Visible::From::All', 'sym') },
        X::Agrammon::Outputs::IsSingleInstance,
        module => 'Visible::From::All',
        name => 'sym';

    is-deeply $outputs.get-outputs-hash(),
        {
            'Visible::From::All' => { sym => 99 },
             'Multi::Instance' => [
                 'Instance 1' => {
                     'Multi::Instance::Foo' => { bar => 10 },
                     'Multi::Instance::Bar' => { baz => 20 },
                     'Multi::Instance' => { 'wat' => 30 }
                 },
                 'Instance 2' => {
                     'Multi::Instance::Foo' => { bar => 50 },
                     'Multi::Instance::Bar' => { baz => 60 },
                     'Multi::Instance' => { 'wat' => 70 }
                 }
             ]
        },
        'Getting multi-instance outputs works';
}

done-testing;
