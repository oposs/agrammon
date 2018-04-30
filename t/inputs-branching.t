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

done-testing;
