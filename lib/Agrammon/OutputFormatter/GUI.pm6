use Agrammon::Model;
use Agrammon::Outputs;

# "data":[
#     {"format":"%.0f",
#      "fullValue":8901.71040895108,
#      "labels":{"de":"Total NH3-Emission","en":"Total NH3-Emissions","fr":"Emission de NH3 Total","sort":"999"},
#      "order":"999",
#      "print":"FullTotal",
#      "units":{"de":"kg N\/Jahr","en":"kg N\/year","fr":"kg N\/an"},
#      "value":"8902",
#      "var":"Total::nh3_ntotal"
#     },

#     {"format":null,
#      "fullValue":0,
#      "labels":{"de":null,"en":null,"fr":null,"it":null},
#      "order":null,
#      "print":"15",
#      "units":{"de":"-","en":"-","fr":"-","it":"-"},
#      "value":0,
#      "var":"Livestock::DairyCow[MKühe - generated 0]::Housing::Floor::c_UNECE"
#     },
# ],

# "log":[
#   {"msg":{
#       "de":"Sie haben eine zusätzliche emissionsmindernde Massnahme für einen  Stall der Kategorie Schweine von 10% eingegeben.\n",
#       "en":"You have entered an additional emission mitigation measure for a housing of the category pigs of 10%.\n",
#       "fr":"Vous avez introduit une mesure supplémentaire limitant les émissions dans les stabulations pour porcs de 10%.\n"
#       },
#    "var":"Livestock_Pig_Housing_CFreeFactor::c_free_factor_housing"}
# ],

# "pid":12799,

# "raw":{
#     "Application":{
#         "Out_n_out_application":16904.219771848,
#         "Out_nh3_napplication":5003.75411869633,
#         "Out_nh3_napplication_liquid":3102.5897819671,
#         "Out_nh3_napplication_solid":1901.16433672924,
#         "Out_tan_out_application":5811.54099047595
#     },

#     "End":{},

#     "Livestock":{
#         "Out_n_excretion":31380.007,"Out_n_into_storage":23631.6532900575,"Out_n_into_storage_liquid":13963.9310278187,"Out_n_into_storage_liquid_check":13107.931274394,"Out_n_into_storage_liquid_pigs":449.37637437,"Out_n_into_storage_poultry":0,"Out_n_into_storage_poultry_layers_growers_other_poultry":0,"Out_n_into_storage_poultry_turkeys_broilers":0,"Out_n_into_storage_solid":9667.72226223876,"Out_n_into_storage_solid_dairycows_cattle":9667.72226223876,"Out_n_into_storage_solid_dairycows_cattle_pigs":9667.72226223876,"Out_n_into_storage_solid_horses_otherequides_smallruminants":0,"Out_n_into_storage_solid_pigs":0,"Out_n_remain_pasture":5626.07681920091,"Out_nh3_ngrazing":294.862792671233,"Out_nh3_nhousing":1207.55220765944,"Out_nh3_nhousing_and_yard":1827.4140980704,"Out_nh3_nlivestock":2122.27689074163,"Out_nh3_nyard":619.861890410959,"Out_tan_excretion":18881.0649,"Out_tan_into_storage":13501.0870348063,"Out_tan_into_storage_liquid":7898.88189357212,"Out_tan_into_storage_liquid_pigs":290.19427437,"Out_tan_into_storage_poultry":0,"Out_tan_into_storage_poultry_layers_growers_other_poultry":0,"Out_tan_into_storage_poultry_turkeys_broilers":0,"Out_tan_into_storage_solid":5602.20514123419,"Out_tan_into_storage_solid_dairycows_cattle":5602.20514123419,"Out_tan_into_storage_solid_horses_otherequides_smallruminants":0,"Out_tan_into_storage_solid_pigs":0,"Out_tan_to_grazing":3552.56376712329
#     },

#     "Livestock_DairyCow_Excretion":{
#         "AVERAGE":{
#             "Out_dairy_cows":130,"Out_n_excretion":15039.7,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":9023.82
#         },
#         "INST":{
#             "MKühe - generated 0":{
#                 "Out_dairy_cows":200,"Out_n_excretion":23138,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":13882.8
#             },
#             "Stall Milchkühe - generated 0":{
#                 "Out_dairy_cows":60,"Out_n_excretion":6941.4,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":4164.84
#             }
#         },
#         "SUM":{
#             "Out_dairy_cows":260,"Out_n_excretion":30079.4,"Out_n_excretion_animal":231.38,"Out_n_sol_excretion":18047.64
#         }
#     },
# }

#     "Livestock_DairyCow_Excretion":{
#         "AVERAGE":{"Out_dairy_cows":130,"Out_n_excretion":15039.7,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":9023.82},
#         "INST":{
#             "MKühe - generated 0":{"Out_dairy_cows":200,"Out_n_excretion":23138,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":13882.8},
#             "Stall Milchkühe - generated 0":{"Out_dairy_cows":60,"Out_n_excretion":6941.4,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":4164.84}
#         },
#         "SUM":{"Out_dairy_cows":260,"Out_n_excretion":30079.4,"Out_n_excretion_animal":231.38,"Out_n_sol_excretion":18047.64}
#     },
#     "Livestock_DairyCow_Excretion":{
#         "AVERAGE":{"Out_dairy_cows":130,"Out_n_excretion":15039.7,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":9023.82},
#         "INST":{
#             "MKühe - generated 0":{"Out_dairy_cows":200,"Out_n_excretion":23138,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":13882.8},
#             "Stall Milchkühe - generated 0":{"Out_dairy_cows":60,"Out_n_excretion":6941.4,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":4164.84}
#         },
#         "SUM":{"Out_dairy_cows":260,"Out_n_excretion":30079.4,"Out_n_excretion_animal":231.38,"Out_n_sol_excretion":18047.64}
#     },
#     "Livestock_DairyCow_Excretion":{
#         "AVERAGE":{"Out_dairy_cows":130,"Out_n_excretion":15039.7,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":9023.82},
#         "INST":{
#             "MKühe - generated 0":{"Out_dairy_cows":200,"Out_n_excretion":23138,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":13882.8},
#             "Stall Milchkühe - generated 0":{"Out_dairy_cows":60,"Out_n_excretion":6941.4,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":4164.84}
#         },
#         "SUM":{"Out_dairy_cows":260,"Out_n_excretion":30079.4,"Out_n_excretion_animal":231.38,"Out_n_sol_excretion":18047.64}
#     },
#     "Livestock_DairyCow_Excretion":{
#         "AVERAGE":{"Out_dairy_cows":130,"Out_n_excretion":15039.7,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":9023.82},
#         "INST":{
#             "MKühe - generated 0":{"Out_dairy_cows":200,"Out_n_excretion":23138,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":13882.8},
#             "Stall Milchkühe - generated 0":{"Out_dairy_cows":60,"Out_n_excretion":6941.4,"Out_n_excretion_animal":115.69,"Out_n_sol_excretion":4164.84}
#         },
#         "SUM":{"Out_dairy_cows":260,"Out_n_excretion":30079.4,"Out_n_excretion_animal":231.38,"Out_n_sol_excretion":18047.64}
#     },

sub output-for-gui(Agrammon::Model $model,
                   Agrammon::Outputs $outputs) is export {
    my %output = %(
        data => _get_data($model, $outputs),
        log  => %(),
        pid  => 333,
#        raw  => _get_raw($model, $outputs)
    );
    return %output;
}

#sub _get_raw($model, $outputs) {
#    return ();
#}

sub _get_data($model, $outputs) {
    my @records;
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        when Hash {
            for sorted-kv($_) -> $output, $value {
                my $format = $model.output-format($module, $output);
#                dd $output, $value, $format;
                my $formattedValue = $format ?? sprintf($format, $value)
                                             !! $value;
                push @records, %(
                    format    => $format,
                    print     => $model.output-print($module, $output),
                    order     => $model.output-order($module, $output),
                    labels    => $model.output-labels($module, $output),
                    units     => $model.output-units($module, $output),
                    fullValue => $value,
                    value     => $formattedValue,
                    var       =>  $module ~ '::' ~ $output,
                );
            }
        }
        when Array {
            for sorted-kv($_) -> $instance-id, %instance-outputs {
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    for sorted-kv(%values) -> $output, $value {
                        my $format = $model.output-format($fq-name, $output);
                        my $formattedValue = $format ?? sprintf($format, $value)
                                                     !! $value;
                        push @records, %(
                            format    => $format,
                            print     => $model.output-print($fq-name, $output),
                            order     => $model.output-order($fq-name, $output),
                            labels    => $model.output-labels($fq-name, $output),
                            units     => $model.output-units($fq-name, $output),
                            fullValue => $value,
                            value     => $formattedValue,
                            var       =>  $q-name ~ '::' ~ $output,
                        );

#                        $csv.combine($simulation-name, $dataset-id, $q-name, $output, $value,
#                                $model.output-unit($fq-name, $output, $unit-language));
#                        push @lines, $csv.string;
                    }
                }
            }
        }
    }
    return @records;
}

sub sorted-kv($_) {
    .sort(*.key).map({ |.kv })
}
