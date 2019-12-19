use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::Model::Parameters;
use Agrammon::TechnicalParser;

use Test;

my $path = $*PROGRAM.parent.add('test-data/Models/with-filters');
my $model = Agrammon::Model.new(:$path);
lives-ok { $model.load('End') },
        'Can load a set of modules that makes use of filter inputs';

subtest 'We know if an input is declared as being a filter or not' => {
    given $model.evaluation-order.first(*.taxonomy eq 'Livestock::Pig::Excretion') -> $excretion {
        isa-ok $excretion, Agrammon::Model::Module, 'Found pig excretion module';
        given $excretion.input.first(*.name eq 'animalcategory') -> $input {
            isa-ok $input, Agrammon::Model::Input, 'Found animal category input';
            ok $input.is-filter, 'We filter on this input';
        }
        given $excretion.input.first(*.name eq 'pigs') -> $input {
            isa-ok $input, Agrammon::Model::Input, 'Found pigs input';
            nok $input.is-filter, 'We do not filter on this input';
        }
    }
}

subtest 'Running the model produces output instances with filters' => {
    my $fh = open $*PROGRAM.parent.add('test-data/complex-model-input.csv');
    my @datasets = Agrammon::DataSource::CSV.new().read($fh);
    is @datasets.elems, 1, 'Got the one expected data set to run';
    $fh.close;

    my $params;
    lives-ok
            { $params = parse-technical($*PROGRAM.parent.add('test-data/Models/with-filters/technical.cfg').slurp) },
            'Parsed technical file';
    isa-ok $params, Agrammon::Model::Parameters, 'Correct type for technical data';

    my Agrammon::Outputs $output;
    lives-ok
            {
                $output = $model.run(
                        input => @datasets[0],
                        technical => %($params.technical.map(-> %module {
                            %module.keys[0] => %(%module.values[0].map({ .name => .value }))
                        })))
            },
            'Successfully executed model';

    my @instances = $output.find-instances('Livestock::Pig').sort(*.key).map(*.value);
    is @instances.elems, 4, 'Have expected number of pig instances';
    is-deeply @instances[0].filters,
            { 'Livestock::Pig::Excretion::animalcategory' => 'boars' },
            'Correct filters on pig (1)';
    is-deeply @instances[1].filters,
            { 'Livestock::Pig::Excretion::animalcategory' => 'dry_sows' },
            'Correct filters on pig (2)';
    is-deeply @instances[2].filters,
            { 'Livestock::Pig::Excretion::animalcategory' => 'nursing_sows' },
            'Correct filters on pig (3)';
    is-deeply @instances[3].filters,
            { 'Livestock::Pig::Excretion::animalcategory' => 'weaned_piglets_up_to_25kg' },
            'Correct filters on pig (4)';
}

done-testing;
