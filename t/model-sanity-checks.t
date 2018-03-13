use v6;
use Agrammon::Model;
use Test;

my $path = $*PROGRAM.parent.add('test-data/Models/bad');

throws-like
    { Agrammon::Model.new(path => $path).load('InvalidIn') },
    X::Agrammon::Model::InvalidInput,
    module => 'InvalidIn',
    output => 'result',
    input => 'chimps';

throws-like
    { Agrammon::Model.new(path => $path).load('InvalidTech') },
    X::Agrammon::Model::InvalidTechnical,
    module => 'InvalidTech',
    output => 'result',
    technical => 'add';

done-testing;
