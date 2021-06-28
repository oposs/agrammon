use v6;
use JSON::Fast;

use Agrammon::Inputs;

class Agrammon::DataSource::JSON {
    method load($simulation-name, $dataset-id, $json-data) {
        my %input-data = from-json $json-data;
        my $inputs = Agrammon::Inputs.new(:$simulation-name, :$dataset-id);
        for %input-data.kv -> $full-tax, $module-data {
            if $module-data ~~ Array {
                for @($module-data) {
                    my $instance = $_<name>;
                    my $values = $_<values>;
#                    note "    $instance";
                    for $values.kv -> $sub-tax, $instance-inputs {
#                        note "        $sub-tax";
                        for $instance-inputs.kv -> $var, $value {
#                            note "            $var : $value";
                            $inputs.add-multi-input(
                                $full-tax, $instance, $sub-tax,
                                $var, $value
                            );
                        }
                    }
                }
            }
            else {
                for $module-data -> $input-hash {
                    for $input-hash.kv -> $var, $value {
#                        note "                $var : $value";
                        $inputs.add-single-input($full-tax, $var, $value);
                    }
                }

            }
        }
        return $inputs;
    }
}

# JSON input expected
#{
#    "simulation": "2010v2.1_20120425",
#    "run": "2648",
#    "inputs": {
#        "Application::Slurry::Applrate": {
#            "appl_rate": "20",
#            "dilution_parts_water": "1.0000"
#        },
#        "Livestock::DairyCow": [
#            {
#                "name": "DC_Ex1",
#                "values": {
#                    "Excretion": {
#                        "animalcategory": "dairy_cows",
#                        "animals": "10"
#                    }
#                },
#                "Excretion::CFeedWinterRatio": {
#                    "share_beets_winter": 0,
#                    "share_grass_silage_winter": 0
#                },
#                "Housing::Type": {
#                    "housing_type": "Loose_Housing_Slurry_Plus_Solid_Manure"
#                }
#            },
#            {
#                "name": "DC_Standard",
#                "values": {
#                    "Excretion": {
#                        "animalcategory": "dairy_cows",
#                        "animals": "10"
#                    },
#                    "Excretion::CFeedWinterRatio": {
#                        "share_beets_winter": 0,
#                        "share_grass_silage_winter": 0
#                    },
#                    "Housing::Type": {
#                        "housing_type": "Loose_Housing_Slurry_Plus_Solid_Manure"
#                    }
#                }
#            }
#        ]
#    }
#}
