use v6;
use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::Model::Parameters;
use Agrammon::Outputs::FilterGroupCollection;
use Agrammon::TechnicalParser;
use Agrammon::OutputFormatter::CSV;
use Agrammon::OutputFormatter::JSON;
use Agrammon::OutputFormatter::Text;
use JSON::Fast;

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

    my %technical = $params.technical.map: -> %module {
        %module.keys[0] => %(%module.values[0].map({ .name => .value }))
    }
    lives-ok { @datasets>>.apply-defaults($model, %technical) },
        'Could apply defaults to inputs';

    my Agrammon::Outputs $output;
    $start = now;
    lives-ok
            {
                $output = $model.run:
                        input => @datasets[0],
                        technical => %technical
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
            given translate-filter-keys($model, .[0].key) -> %translated {
                is %translated.elems, 1, 'Translated filter key hash has one element';
                is-deeply %translated.keys[0],
                    {:de("Tierkategorie"), :en("Animal category"), :fr("Catégorie d'animaux")},
                    'Correct translation of key';
                is-deeply %translated.values[0],
                    {:de("Eber"), :en("boars"), :fr("Verrats"), :it("boars")},
                    'Correct translation of value';
            }
        }
        my @all-results-by-group = $livestock-tan.results-by-filter-group(:all);
        given @all-results-by-group[0] {
            ok .key eqv {"Livestock::Pig::Excretion::animalcategory" => 'nursing_sows'},
                    'First key is first enum element';
            is-deeply .value, <347116/5625>, 'Correct value';
        }
        given @all-results-by-group[2] {
            ok .key eqv {"Livestock::Pig::Excretion::animalcategory" => 'gilts'},
                'Have a key included without a value';
            is-deeply .value, 0, 'Zero value';
        }
    }

    subtest 'filterGroup builtin' => {
        given $output.get-output('Livestock', 'factors') -> $factor {
            isa-ok $factor, Agrammon::Outputs::FilterGroupCollection,
                    'filterGroup builtin will produce a filter group collection';
            my @results-by-group = $factor.results-by-filter-group;
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

    subtest 'Output formatters with filter groups' => {
        my $include-filters = True;
        my @print-set = <LivestockTotal OtherPigFlux>;

        my $csv = output-as-csv('Demo', 'Test', $model, $output, "en", @print-set, $include-filters) ~ "\n";
        is $csv, q:to/OUTPUT/, 'Correct CSV output';
            Demo;Test;SummaryByAnimalCategory;n_excretion_otherpig;;141.003688;kg N/year
            Demo;Test;SummaryByAnimalCategory;n_excretion_otherpig;nursing_sows;88.156444;kg N/year
            Demo;Test;SummaryByAnimalCategory;n_excretion_otherpig;dry_sows;0;kg N/year
            Demo;Test;SummaryByAnimalCategory;n_excretion_otherpig;weaned_piglets_up_to_25kg;20.826;kg N/year
            Demo;Test;SummaryByAnimalCategory;n_excretion_otherpig;boars;32.021244;kg N/year
            Demo;Test;Total;nh3_nanimalproduction;;352.7111423399035;kg N/year
            OUTPUT

        my $text = output-as-text($model, $output, "en", @print-set, $include-filters) ~ "\n";
        is $text, q:to/OUTPUT/, 'Correct text output';
            SummaryByAnimalCategory
                n_excretion_otherpig = 141.003688 kg N/year
                  * Livestock::Pig::Excretion::animalcategory=nursing_sows                 88.156444 kg N/year
                  * Livestock::Pig::Excretion::animalcategory=dry_sows                     0 kg N/year
                  * Livestock::Pig::Excretion::animalcategory=weaned_piglets_up_to_25kg    20.826 kg N/year
                  * Livestock::Pig::Excretion::animalcategory=boars                        32.021244 kg N/year
            Total
                nh3_nanimalproduction = 352.7111423399035 kg N/year
            OUTPUT

        my $json = output-as-json($model, $output, "en", @print-set, $include-filters);
        is to-json($json, :sorted-keys) ~ "\n", q:to/OUTPUT/, "Correct JSON output";
            [
              {
                "filters": [
                ],
                "format": "%.0f",
                "fullValue": 141.003688,
                "label": null,
                "order": -1,
                "print": "OtherPigFlux",
                "unit": "kg N/year",
                "value": "141",
                "var": "SummaryByAnimalCategory::n_excretion_otherpig"
              },
              {
                "filters": [
                  {
                    "enum": {
                      "de": "Säugende Sauen",
                      "en": "nursing sows",
                      "fr": "Truies allaitantes",
                      "it": "nursing sows"
                    },
                    "label": {
                      "de": "Tierkategorie",
                      "en": "Animal category",
                      "fr": "Catégorie d'animaux"
                    }
                  }
                ],
                "format": "%.0f",
                "fullValue": 88.156444,
                "labels": {
                },
                "order": -1,
                "print": "OtherPigFlux",
                "units": {
                  "de": "kg N/Jahr",
                  "en": "kg N/year",
                  "fr": "kg N/an"
                },
                "value": "88",
                "var": "SummaryByAnimalCategory::n_excretion_otherpig"
              },
              {
                "filters": [
                  {
                    "enum": {
                      "de": "Galtsauen",
                      "en": "dry sows",
                      "fr": "Truies gestantes",
                      "it": "dry sows"
                    },
                    "label": {
                      "de": "Tierkategorie",
                      "en": "Animal category",
                      "fr": "Catégorie d'animaux"
                    }
                  }
                ],
                "format": "%.0f",
                "fullValue": 0.0,
                "labels": {
                },
                "order": -1,
                "print": "OtherPigFlux",
                "units": {
                  "de": "kg N/Jahr",
                  "en": "kg N/year",
                  "fr": "kg N/an"
                },
                "value": "0",
                "var": "SummaryByAnimalCategory::n_excretion_otherpig"
              },
              {
                "filters": [
                  {
                    "enum": {
                      "de": "Ferkel abgesetzt bis 25 kg",
                      "en": "weaned piglets up to 25kg",
                      "fr": "Porcelets sevrés jusqu' à 25 kg",
                      "it": "weaned piglets up to 25kg"
                    },
                    "label": {
                      "de": "Tierkategorie",
                      "en": "Animal category",
                      "fr": "Catégorie d'animaux"
                    }
                  }
                ],
                "format": "%.0f",
                "fullValue": 20.826,
                "labels": {
                },
                "order": -1,
                "print": "OtherPigFlux",
                "units": {
                  "de": "kg N/Jahr",
                  "en": "kg N/year",
                  "fr": "kg N/an"
                },
                "value": "21",
                "var": "SummaryByAnimalCategory::n_excretion_otherpig"
              },
              {
                "filters": [
                  {
                    "enum": {
                      "de": "Eber",
                      "en": "boars",
                      "fr": "Verrats",
                      "it": "boars"
                    },
                    "label": {
                      "de": "Tierkategorie",
                      "en": "Animal category",
                      "fr": "Catégorie d'animaux"
                    }
                  }
                ],
                "format": "%.0f",
                "fullValue": 32.021244,
                "labels": {
                },
                "order": -1,
                "print": "OtherPigFlux",
                "units": {
                  "de": "kg N/Jahr",
                  "en": "kg N/year",
                  "fr": "kg N/an"
                },
                "value": "32",
                "var": "SummaryByAnimalCategory::n_excretion_otherpig"
              },
              {
                "filters": [
                ],
                "format": "%.0f",
                "fullValue": 352.7111423399035e0,
                "label": "Total Animalproduction NH3-Emissions",
                "order": "890",
                "print": "LivestockTotal",
                "unit": "kg N/year",
                "value": "353",
                "var": "Total::nh3_nanimalproduction"
              }
            ]
            OUTPUT

        # output-for-gui is not filtered by @print-set and thus gets all outputs
        # we just compare a few to cover filters and no filters
        my $gui = output-for-gui($model, $output, :language("en"), :$include-filters);
        is to-json($gui<data>[^3], :sorted-keys) ~ "\n", q:to/OUTPUT/, "Correct GUI output";
            [
              {
                "filters": [
                ],
                "format": "%.0f",
                "fullValue": 961.003688,
                "label": "Total N excretion",
                "order": "101",
                "print": "FluxSummaryLivestock",
                "unit": "kg N/year",
                "value": "961",
                "var": "Livestock::n_excretion"
              },
              {
                "filters": [
                ],
                "format": "%.0f",
                "fullValue": 590.702582,
                "label": "Total soluble N excretion",
                "order": "101",
                "print": "TANFlux",
                "unit": "kg TAN/year",
                "value": "591",
                "var": "Livestock::tan_excretion"
              },
              {
                "filters": [
                  {
                    "enum": {
                      "de": "Säugende Sauen",
                      "en": "nursing sows",
                      "fr": "Truies allaitantes",
                      "it": "nursing sows"
                    },
                    "label": {
                      "de": "Tierkategorie",
                      "en": "Animal category",
                      "fr": "Catégorie d'animaux"
                    }
                  }
                ],
                "format": "%.0f",
                "fullValue": 61.709511,
                "labels": {
                  "de": "Total Nlös Ausscheidung",
                  "en": "Total soluble N excretion",
                  "fr": "Excrétion de TAN totale",
                  "sort": "101"
                },
                "order": "101",
                "print": "TANFlux",
                "units": {
                  "de": "kg TAN/Jahr",
                  "en": "kg TAN/year",
                  "fr": "kg TAN/an"
                },
                "value": "62",
                "var": "Livestock::tan_excretion"
              }
            ]
            OUTPUT

    }

}

done-testing;
