DELETE FROM data_new WHERE data_var IN (
'Livestock::DairyCow[]::Housing::ClimateAir::mitigation_options_for_housing_systems_for_dairy_cows_climate',
'Livestock::DairyCow[]::Housing::ClimateAir::mitigation_options_for_housing_systems_for_dairy_cows_air',
'Livestock::DairyCow[]::Housing::Type::feeding_boxes',
'Livestock::OtherCattle[]::Housing::ClimateAir::mitigation_options_for_housing_systems_for_other_cattle_climate',
'Livestock::OtherCattle[]::Housing::ClimateAir::mitigation_options_for_housing_systems_for_other_cattle_air',
'Livestock::OtherCattle[]::Housing::Type::feeding_boxes',
'Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_fattening_pigs_climate',
'Livestock::FatteningPigs[]::Housing::Type::exercise_place',
'Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_climate',
'Livestock::Pig[]::Housing::Type::exercise_place')
AND data_dataset IN (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
