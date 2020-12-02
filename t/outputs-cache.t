use v6;
use Agrammon::OutputsCache;
use Test;

{
    my $cache = Agrammon::OutputsCache.new;

    my $calculated;
    my $fake-output = Agrammon::Outputs.new;
    my $result = $cache.get-or-calculate('user1', 'dataset1', -> {
        $calculated = True;
        $fake-output
    });
    ok $calculated, 'First lookup results in calculation taking place';
    ok $result === $fake-output, 'Got calculated result back';

    $calculated = False;
    $result = $cache.get-or-calculate('user1', 'dataset1', -> {
        $calculated = True;
        $fake-output
    });
    nok $calculated, 'Cache was used on second lookup';
    ok $result === $fake-output, 'Got previously calculated result back';

    lives-ok { $cache.invalidate('user1', 'dataset2') },
        'Can invalidate an entry that is not in the cache';
    $calculated = False;
    $result = $cache.get-or-calculate('user1', 'dataset1', -> {
        $calculated = True;
        $fake-output
    });
    nok $calculated, 'Entry was not wrongly invalidated';

    lives-ok { $cache.invalidate('user1', 'dataset1') },
            'Can invalidate an entry that is really in the cache';
    $calculated = False;
    my $new-fake-output = Agrammon::Outputs.new;
    $result = $cache.get-or-calculate('user1', 'dataset1', -> {
        $calculated = True;
        $new-fake-output
    });
    ok $calculated, 'Lookup after invalidation calculates again';
    ok $result === $new-fake-output, 'Got newly calculated result back';
}

done-testing;
