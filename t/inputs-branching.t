use Agrammon::Inputs;
use Test;

given Agrammon::Inputs::Distribution.new -> $dist {
    lives-ok { $dist.add-single-input('Foo::Foo', 'single', 42) },
            'Can add single input to input distribution';
    lives-ok { $dist.add-multi-input('Foo::Bar', 'Instance A', 'Baz', 'val', 101) },
            'Can add multi input to input distribution';
    lives-ok
            {
                $dist.add-multi-input-branched('Foo::Bar', 'Instance C', 'Baz',
                        'kind', <abc def>, 'volume', <quiet medium loud>,
                        [[20, 10, 20],[30, 20, 0]])
            },
            'Can add branched multi input';
    throws-like
            {
                $dist.add-multi-input-branched('Foo::Bar', 'Instance C', 'Baz',
                        'other-kind', <abc def>, 'volume', <quiet medium loud>,
                        [[20, 10, 20],[30, 20, 0]])
            },
            X::Agrammon::Inputs::Distribution::AlreadyBranched,
            'Cannot add duplicate branched input';
    throws-like
            {
                $dist.add-multi-input-flattened('Foo::Bar', 'Instance B', 'Baz',
                        'kind', { abc => 10, def => 90 });
                $dist.add-multi-input-branched('Foo::Bar', 'Instance B', 'Baz',
                        'kind', <abc def>, 'volume', <quiet medium loud>,
                        [[20, 10, 20],[30, 20, 0]])
            },
            X::Agrammon::Inputs::Distribution::AlreadyFlattened,
            'Cannot add branched input that covers a flattened input';
    throws-like
            {
                $dist.add-multi-input-flattened('Foo::Bar', 'Instance C', 'Baz',
                        'kind', { abc => 10, def => 90 })
            },
            X::Agrammon::Inputs::Distribution::AlreadyBranched,
            'Cannot add flattend input that covers a branched input';
    throws-like
            {
                $dist.add-multi-input-branched('Foo::Bar', 'Instance C', 'Baz',
                        'aaa', <x y>, 'bbb', <x y z>,
                        [[20, 10, 30],[30, 20, 10]])
            },
            X::Agrammon::Inputs::Distribution::BadSum,
            'Branch matrix must sum to 100 (1)';
    throws-like
            {
                $dist.add-multi-input-branched('Foo::Bar', 'Instance C', 'Baz',
                        'aaa', <x y>, 'bbb', <x y z>,
                        [[10, 5, 10],[10, 20, 10]])
            },
            X::Agrammon::Inputs::Distribution::BadSum,
            'Branch matrix must sum to 100 (2)';
    throws-like
            {
                $dist.add-multi-input-branched('Foo::Bar', 'Instance C', 'Baz',
                        'aaa', <x y>, 'bbb', <x y z>,
                        [[20, 10, 15],[30, 10, 12],[1,1,1]])
            },
            X::Agrammon::Inputs::Distribution::BadBranchMatrix,
            expected-rows => 2, expected-cols => 3,
            'Wrong number of rows is reported (1)';
    throws-like
            {
                $dist.add-multi-input-branched('Foo::Bar', 'Instance C', 'Baz',
                        'aaa', <x y>, 'bbb', <x y z>,
                        [[20, 50, 30],])
            },
            X::Agrammon::Inputs::Distribution::BadBranchMatrix,
            expected-rows => 2, expected-cols => 3,
            'Wrong number of rows is reported (2)';
    throws-like
            {
                $dist.add-multi-input-branched('Foo::Bar', 'Instance C', 'Baz',
                        'aaa', <x y>, 'bbb', <x y z>,
                        [[20, 30],[30, 20]])
            },
            X::Agrammon::Inputs::Distribution::BadBranchMatrix,
            expected-rows => 2, expected-cols => 3,
            'Wrong number of columns is reported (1)';
    throws-like
            {
                $dist.add-multi-input-branched('Foo::Bar', 'Instance C', 'Baz',
                        'aaa', <x y>, 'bbb', <x y z>,
                        [[10,10,10,20],[10,10,10,20]])
            },
            X::Agrammon::Inputs::Distribution::BadBranchMatrix,
            expected-rows => 2, expected-cols => 3,
            'Wrong number of columns is reported (2)';
}

subtest '1 branched input' => {
    given Agrammon::Inputs::Distribution.new -> $dist {
        $dist.add-multi-input('Test::Base', 'Instance A', 'Sub', 'dist-me', 1000);
        $dist.add-multi-input('Test::Base', 'Instance A', 'Sub', 'simple', 42);
        $dist.add-multi-input-branched('Test::Base', 'Instance A', 'AnotherSub',
                'flat-a', <x y z>, 'flat-b', <a b>,
                [[12,18], [8,12], [20,30]]);
        $dist.add-multi-input('Test::Base', 'Instance A', 'AnotherSub', 'simple', 101);
        my $inputs = $dist.to-inputs({ 'Test::Base' => 'Test::Base::Sub::dist-me' });
        my @instances = $inputs.inputs-list-for('Test::Base');
        is @instances.elems, 6, 'Produced 6 instances from the distribution';
        @instances .= sort({ .<flat-b>, .<flat-a> given .input-hash-for('Test::Base::AnotherSub') });
        is-deeply @instances[0].input-hash-for('Test::Base::Sub'),
                { dist-me => 120, simple => 42 }, 'Correct distribution value for first flattened input';
        is-deeply @instances[0].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'x', flat-b => 'a', simple => 101 }, 'Correct enum value for first flattened input';
        is-deeply @instances[1].input-hash-for('Test::Base::Sub'),
                { dist-me => 80, simple => 42 }, 'Correct distribution value for second flattened input';
        is-deeply @instances[1].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'y', flat-b => 'a', simple => 101 }, 'Correct enum value for second flattened input';
        is-deeply @instances[2].input-hash-for('Test::Base::Sub'),
                { dist-me => 200, simple => 42 }, 'Correct distribution value for third flattened input';
        is-deeply @instances[2].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'z', flat-b => 'a', simple => 101 }, 'Correct enum value for third flattened input';
        is-deeply @instances[3].input-hash-for('Test::Base::Sub'),
                { dist-me => 180, simple => 42 }, 'Correct distribution value for fourth flattened input';
        is-deeply @instances[3].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'x', flat-b => 'b', simple => 101 }, 'Correct enum value for fourth flattened input';
        is-deeply @instances[4].input-hash-for('Test::Base::Sub'),
                { dist-me => 120, simple => 42 }, 'Correct distribution value for fifth flattened input';
        is-deeply @instances[4].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'y', flat-b => 'b', simple => 101 }, 'Correct enum value for fifth flattened input';
        is-deeply @instances[5].input-hash-for('Test::Base::Sub'),
                { dist-me => 300, simple => 42 }, 'Correct distribution value for sixth flattened input';
        is-deeply @instances[5].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'z', flat-b => 'b', simple => 101 }, 'Correct enum value for sixth flattened input';
    }
}

subtest '1 branched input and 1 flattened input' => {
    given Agrammon::Inputs::Distribution.new -> $dist {
        $dist.add-multi-input('Test::Base', 'Instance A', 'Sub', 'dist-me', 1000);
        $dist.add-multi-input('Test::Base', 'Instance A', 'Sub', 'simple', 42);
        $dist.add-multi-input-branched('Test::Base', 'Instance A', 'AnotherSub',
                'flat-a', <x y>, 'flat-b', <a b>,
                [[8,12], [32,48]]);
        $dist.add-multi-input-flattened('Test::Base', 'Instance A', 'AnotherSub', 'flat-c',
                {c => 70, d => 30 });
        $dist.add-multi-input('Test::Base', 'Instance A', 'AnotherSub', 'simple', 101);
        my $inputs = $dist.to-inputs({ 'Test::Base' => 'Test::Base::Sub::dist-me' });
        my @instances = $inputs.inputs-list-for('Test::Base');
        is @instances.elems, 8, 'Produced 8 instances from the distribution';
        @instances .= sort({ .<flat-a>, .<flat-b>, .<flat-c> given .input-hash-for('Test::Base::AnotherSub') });
        is-deeply @instances[0].input-hash-for('Test::Base::Sub'),
                { dist-me => 56, simple => 42 }, 'Correct distribution value for first flattened input';
        is-deeply @instances[0].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'x', flat-b => 'a', flat-c => 'c', simple => 101 },
                'Correct enum value for first flattened input';
        is-deeply @instances[1].input-hash-for('Test::Base::Sub'),
                { dist-me => 24, simple => 42 }, 'Correct distribution value for second flattened input';
        is-deeply @instances[1].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'x', flat-b => 'a', flat-c => 'd', simple => 101 },
                'Correct enum value for second flattened input';
        is-deeply @instances[2].input-hash-for('Test::Base::Sub'),
                { dist-me => 84, simple => 42 }, 'Correct distribution value for third flattened input';
        is-deeply @instances[2].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'x', flat-b => 'b', flat-c => 'c', simple => 101 },
                'Correct enum value for third flattened input';
        is-deeply @instances[3].input-hash-for('Test::Base::Sub'),
                { dist-me => 36, simple => 42 }, 'Correct distribution value for forth flattened input';
        is-deeply @instances[3].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'x', flat-b => 'b', flat-c => 'd', simple => 101 },
                'Correct enum value for forth flattened input';
        is-deeply @instances[4].input-hash-for('Test::Base::Sub'),
                { dist-me => 224, simple => 42 }, 'Correct distribution value for fifth flattened input';
        is-deeply @instances[4].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'y', flat-b => 'a', flat-c => 'c', simple => 101 },
                'Correct enum value for fifth flattened input';
        is-deeply @instances[5].input-hash-for('Test::Base::Sub'),
                { dist-me => 96, simple => 42 }, 'Correct distribution value for sixth flattened input';
        is-deeply @instances[5].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'y', flat-b => 'a', flat-c => 'd', simple => 101 },
                'Correct enum value for sixth flattened input';
        is-deeply @instances[6].input-hash-for('Test::Base::Sub'),
                { dist-me => 336, simple => 42 }, 'Correct distribution value for seventh flattened input';
        is-deeply @instances[6].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'y', flat-b => 'b', flat-c => 'c', simple => 101 },
                'Correct enum value for seventh flattened input';
        is-deeply @instances[7].input-hash-for('Test::Base::Sub'),
                { dist-me => 144, simple => 42 }, 'Correct distribution value for eigth flattened input';
        is-deeply @instances[7].input-hash-for('Test::Base::AnotherSub'),
                { flat-a => 'y', flat-b => 'b', flat-c => 'd', simple => 101 },
                'Correct enum value for eigth flattened input';
    }
}

done-testing;
