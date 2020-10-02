use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::Model::Parameters;
use Agrammon::TechnicalParser;

use Test;

sub timed(Str $title, &proc) is export {
    my $start = now;
    my \ret   = proc;
    my $end   = now;
    note sprintf "$title ran %.3f seconds", $end-$start;
    return ret;
}

my $path = $*PROGRAM.parent.add('test-data/Models/with-filters');
my $start = now;

my $model = Agrammon::Model.new(:$path);
lives-ok { $model.load('End') },
        'Can load a set of modules that makes use of filter inputs';
    my $end = now;
    note sprintf "Model loaded in %.3f seconds", $end-$start;

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
    my $fh = open $*PROGRAM.parent.add('test-data/complex-model-with-filters-input.csv');
    my @datasets = Agrammon::DataSource::CSV.new().read($fh);
    is @datasets.elems, 1, 'Got the one expected data set to run';
    $fh.close;
    my $end = now;
    note sprintf "Inputs loaded in %.3f seconds", $end-$start;

    my $params;
    $start = now;
    lives-ok
            { $params = parse-technical($*PROGRAM.parent.add('test-data/Models/with-filters/technical.cfg').slurp) },
            'Parsed technical file';
    $end = now;
    note sprintf "Parameters loaded in %.3f seconds", $end-$start;
    isa-ok $params, Agrammon::Model::Parameters, 'Correct type for technical data';

    my Agrammon::Outputs $output;
    $start = now;
    lives-ok
            {
                $output = $model.run(
                        input => @datasets[0],
                        technical => %($params.technical.map(-> %module {
                            %module.keys[0] => %(%module.values[0].map({ .name => .value }))
                        })))
            },
            'Successfully executed model';
    $end   = now;
    note sprintf "Model ran %.3f seconds", $end-$start;

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

    given $output.get-output('Livestock', 'tan_excretion') -> $livestock-tan {
        isa-ok $livestock-tan, Agrammon::Outputs::FilterGroupCollection,
            'Output doing pairwise calculation produces a filter group collection';
        my @results-by-group = $livestock-tan.results-by-filter-group;
        given @results-by-group.grep(*.key eqv {"Livestock::Pig::Excretion::animalcategory" => "boars"}) {
            is .elems, 1, 'Found filter group value for boars';
            is .[0].value, <238158/10625>, 'Correct value calculated for boars';
        }
    }

    subtest 'filterGroup builtin' => {
        given $output.get-output('Livestock', 'factors') -> $factor {
            isa-ok $factor, Agrammon::Outputs::FilterGroupCollection,
                    'filterGroup builtin will produce a filter group collection';
            my @results-by-group = $factor.results-by-filter-group;
            dd @results-by-group;
            given @results-by-group.grep(*.key eqv { "Livestock::Pig::Excretion::animalcategory" => "boars" }) {
                is .elems, 1, 'Found filter group value for boars';
                is .[0].value, 0.75, 'Correct value for boars';
            }
            given @results-by-group.grep(*.key eqv { "Livestock::Pig::Excretion::animalcategory" => "dry_sows" }) {
                is .elems, 1, 'Found filter group value for dry sows';
                is .[0].value, 0.5, 'Correct value for dry sows';
            }
        }
    }

    subtest 'Final outputs still correct even with filter groups in effect' => {
        is $output.get-output('Total', 'nh3_ntotal'),
                455.8311423399035e0,
                'Correct nh3_ntotal result';
        is $output.get-output('Total', 'nh3_nanimalproduction'),
                352.7111423399035e0,
                'Correct nh3_nanimalproduction result';
    }
}

done-testing;
