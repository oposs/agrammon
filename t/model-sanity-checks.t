use v6;
use Agrammon::Model;
use Test;

my $path = $*PROGRAM.parent.add('test-data/Models/bad');

throws-like
    { Agrammon::Model.new(:$path).load('InvalidIn') },
    X::Agrammon::Model::InvalidInput,
    module => 'InvalidIn',
    output => 'result',
    input => 'chimps';

throws-like
    { Agrammon::Model.new(:$path).load('InvalidTech') },
    X::Agrammon::Model::InvalidTechnical,
    module => 'InvalidTech',
    output => 'result',
    technical => 'add';

throws-like
    { Agrammon::Model.new(:$path).load('InvalidOut') },
    X::Agrammon::Model::InvalidOutputSymbol,
    module => 'InvalidOut',
    output => 'result',
    from => 'InvalidOut::Sub',
    symbol => 'su_result';

throws-like
    { Agrammon::Model.new(:$path).load('InvalidOutModule') },
    X::Agrammon::Model::InvalidOutputModule,
    module => 'InvalidOutModule',
    output => 'result',
    from => 'Some::Unknown::Module',
    symbol => 'some_sym';

done-testing;
