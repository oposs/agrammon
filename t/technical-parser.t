use v6;
use Agrammon::TechnicalBuilder;
use Agrammon::TechnicalParser;
use Test;

given slurp($*PROGRAM.parent.add('test-data/technical.cfg')) -> $test-data {
    my $parsed = Agrammon::TechnicalParser.parse($test-data, actions => Agrammon::TechnicalBuilder);
    ok $parsed, 'Successfully parsed technical.cfg';

    my $model = $parsed.ast;
    isa-ok $model, Agrammon::Model::Parameters, 'Parsing results in a Parameters object';

    # TODO: check actual data structure
}

done-testing;
