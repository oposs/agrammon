use v6;
use Agrammon::TechnicalBuilder;
use Agrammon::TechnicalParser;
use Test;

given slurp($*PROGRAM.parent.add('test-data/technical.cfg')) -> $test-data {
    my $parsed = Agrammon::TechnicalParser.parse($test-data, actions => Agrammon::TechnicalBuilder);
    ok $parsed, 'Successfully parsed technical.cfg';

    my $model = $parsed.ast;
    isa-ok $model, Agrammon::Model::Parameters, 'Parsing results in a Parameters object';

    my @technical = $model.technical;
    is @technical.elems, 3, 'Have 3 technicals';

    my %expected = (
       'PlantProduction::AgriculturalArea' => {
                er_agricultural_area => 2
       },
       'PlantProduction::RecyclingFertiliser' => {
           er_compost => 0.24,
           er_solid_digestate => 0.24,
           er_liquid_digestate => 0.84,
       },
       'PlantProduction::MineralFertiliser' => {
           er_App_mineral_nitrogen_fertiliser_urea => 0.15,
           er_App_mineral_nitrogen_fertiliser_except_urea => 0.02,
       },
    );
    for ^3 {
        for @technical[$_].kv -> $name, @parameters {
            for @parameters -> $p {
                isa-ok $p, Agrammon::Model::Technical,
                    'Correct technical model type';
                is $p.value, %expected{$name}{$p.name},
                    "Value {$name}::" ~ $p.name ~ "=" ~ $p.value ~ " as expected";
            }
        }
    }
}

done-testing;
