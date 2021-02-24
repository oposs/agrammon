use v6;
use Agrammon::Environment;
use Agrammon::Formula;
use Agrammon::Formula::Compiler;
use Agrammon::Formula::LogCollector;
use Agrammon::Formula::Parser;
use Test;

my $f = parse-formula(q:to/FORMULA/, 'PlantProduction');
    writeLog({
        en => 'hello',
        de => 'hallo',
        fr => 'salut'
    });
    writeLog({
        en => 'goodbye',
        de => 'tschüss',
        fr => 'au revoir'
    });
    FORMULA

{
    lives-ok { compile-formula($f)(Agrammon::Environment.new()) },
        'Calls to writeLog survive with no log collector in place';
}

{
    my $*AGRAMMON-LOG = Agrammon::Formula::LogCollector.new;
    my $*AGRAMMON-TAXONOMY = 'Test::Taxonomy';
    my $*AGRAMMON-OUTPUT = 'SomeOutput';
    lives-ok { compile-formula($f)(Agrammon::Environment.new()) },
        'Can evaluate formula using the log collector';
    is-deeply $*AGRAMMON-LOG.entries.map(*.messages),
        (
            { en => 'hello', de => 'hallo', fr => 'salut' },
            { en => 'goodbye', de => 'tschüss', fr => 'au revoir' }
        ),
        'The messages method gets hashes with messages in all languages';
    is-deeply $*AGRAMMON-LOG.entries.map(*.taxonomy), ('Test::Taxonomy', 'Test::Taxonomy'),
        'Correct taxonomy collected';
    is-deeply $*AGRAMMON-LOG.entries.map(*.output), ('SomeOutput', 'SomeOutput'),
        'Correct output collected';
    is-deeply $*AGRAMMON-LOG.messages-for-lang('de'),
        [ 'hallo', 'tschüss' ],
        'The messages-for-lang method gets messages in a particular language';
}

done-testing;
