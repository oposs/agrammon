use v6;
use JSON::Fast;

use Agrammon::Inputs;

class Agrammon::DataSource::JSON {
    method load($simulation-name, $dataset-id, $json-data) {
        my %input-data = from-json $json-data;
        my $inputs = Agrammon::Inputs.new(:$simulation-name, :$dataset-id);
        for %input-data.kv -> $full-tax, $module-data {
            if $full-tax.index('[]') -> $sub-start {
                my $tax = $full-tax.substr(0, $sub-start);
                my $sub-tax = $full-tax.substr($sub-start + 2);
                $sub-tax = $sub-tax ?? $sub-tax.substr(2) !! '';
                for $module-data.kv -> $instance, $instance-inputs {
                    for $instance-inputs.kv -> $var, $value {
                        $inputs.add-multi-input(
                            $tax, $instance, $sub-tax,
                            $var, $value
                        );
                    }
                }
            }
            else {
                for $module-data -> $input-hash {
                    for $input-hash.kv -> $var, $value {
                        $inputs.add-single-input($full-tax, $var, $value);
                    }
                }

            }
        }
        return $inputs;
    }
}

# JSON input expected
# {
#     "Storage::SolidManure::Poultry": {
#         "share_covered_basin": "20",
#         "share_applied_direct_poultry_manure": "20"
#     },
#     "Livestock::Equides[]::Outdoor": {
#         "HorsesUp3yr": {
#             "yard_days": "115",
#             "grazing_days": "165",
#             "grazing_hours": "0",
#             "yard_hours": "0",
#             "floor_properties_exercise_yard": "paddock_or_pasture_used_as_exercise_yard"
#         }
#     }
# }
