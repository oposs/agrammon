-- DairyCow
UPDATE data_new SET data_var='Livestock::DairyCow[]::Excretion::dimensioning_barn' WHERE data_var='Livestock::DairyCow[]::Housing::Type::dimensioning_barn'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor' WHERE data_var='Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL') );
DELETE FROM data_new WHERE data_var='Livestock::DairyCow[]::Housing::Floor::mitigation_options_for_housing_systems_for_dairy_cows_floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL') );
UPDATE data_new SET data_var='Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor' WHERE data_var='Livestock::DairyCow[]::Housing::Floor::mitigation_options_for_housing_systems_for_dairy_cows_floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model = 'SingleLU' );
DELETE FROM data_new WHERE data_var='Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model = 'SingleLU' );

UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard' WHERE data_var='Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_SHL'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL') );
DELETE FROM data_new WHERE data_var='Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_SHL'
       AND data_dataset IN (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model NOT IN ('SingleSHL', 'RegionalSHL', 'UNKNOWN') );

UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard' WHERE data_var='Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_LU'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model = 'SingleLU' );
DELETE FROM data_new WHERE data_var='Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_LU'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model NOT IN ('SingleLU', 'UNKNOWN') );

UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::grazing_days' WHERE data_var='Livestock::DairyCow[]::GrazingInput::grazing_days'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::grazing_hours' WHERE data_var='Livestock::DairyCow[]::GrazingInput::grazing_hours'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::yard_days' WHERE data_var='Livestock::DairyCow[]::Yard::yard_days'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::exercise_yard' WHERE data_var='Livestock::DairyCow[]::Yard::exercise_yard'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::free_correction_factor' WHERE data_var='Livestock::DairyCow[]::Yard::free_correction_factor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

-- OtherCattle
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Excretion::dimensioning_barn' WHERE data_var='Livestock::OtherCattle[]::Housing::Type::dimensioning_barn'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor' WHERE data_var='Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL') );
DELETE FROM data_new WHERE data_var='Livestock::OtherCattle[]::Housing::Floor::mitigation_options_for_housing_systems_for_other_cattle_floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL') );
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor' WHERE data_var='Livestock::OtherCattle[]::Housing::Floor::mitigation_options_for_housing_systems_for_other_cattle_floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model = 'SingleLU' );
DELETE FROM data_new WHERE data_var='Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model = 'SingleLU' );

UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard' WHERE data_var='Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_SHL'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL') );
DELETE FROM data_new WHERE data_var='Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_SHL'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model NOT IN ('SingleSHL', 'RegionalSHL', 'UNKNOWN') );

UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard' WHERE data_var='Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_LU'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model = 'SingleLU' );
DELETE FROM data_new WHERE data_var='Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_LU'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model NOT IN ('SingleLU', 'UNKNOWN') );

UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::grazing_days' WHERE data_var='Livestock::OtherCattle[]::GrazingInput::grazing_days'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::grazing_hours' WHERE data_var='Livestock::OtherCattle[]::GrazingInput::grazing_hours'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::yard_days' WHERE data_var='Livestock::OtherCattle[]::Yard::yard_days'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::exercise_yard' WHERE data_var='Livestock::OtherCattle[]::Yard::exercise_yard'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::free_correction_factor' WHERE data_var='Livestock::OtherCattle[]::Yard::free_correction_factor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

-- FatteningPigs
-- 0 data
--UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Excretion::dimensioning_barn' WHERE data_var='Livestock::FatteningPigs[]::Housing::KArea::dimensioning_barn'
--       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_fattening_pigs'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL') );
DELETE FROM data_new WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_fattening_pigs_slurry_channel'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL') );

UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_fattening_pigs_slurry_channel'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model = 'SingleLU' );
DELETE FROM data_new WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_fattening_pigs'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model = 'SingleLU' );

UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_air' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_fattening_pigs_air'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL', 'SingleLU') );

-- Pig
-- 0 data
--UPDATE data_new SET data_var='Livestock::Pig[]::Excretion::dimensioning_barn' WHERE data_var='Livestock::Pig[]::Housing::KArea::dimensioning_barn'
--       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_floor' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_pigs'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL') );
DELETE FROM data_new WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_slurry_channel'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL' ));

UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_floor' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_slurry_channel'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model = 'SingleLU' );
DELETE FROM data_new WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_pigs'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleLU' ));

UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_air' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_air'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL') );
UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_air' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_air'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleLU') and dataset_mod_date <='2021-06-01');

-- Equides
UPDATE data_new SET data_var='Livestock::Equides[]::Housing::CFreeFactor::free_correction_factor' WHERE data_var='Livestock::Equides[]::Housing::free_correction_factor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::Equides[]::GrazingInput::grazing_days' WHERE data_var='Livestock::Equides[]::Grazing::grazing_days'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::Equides[]::GrazingInput::grazing_hours' WHERE data_var='Livestock::Equides[]::Grazing::grazing_hours'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

UPDATE data_new SET data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard' WHERE data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard_SHL'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('SingleSHL', 'RegionalSHL') );
DELETE FROM data_new WHERE data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard_SHL'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model NOT IN ('SingleSHL', 'RegionalSHL', 'UNKNOWN') );

UPDATE data_new SET data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard' WHERE data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard_LU'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model = 'SingleLU' );
DELETE FROM data_new WHERE data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard_LU'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model NOT IN ('SingleLU', 'UNKNOWN') );

-- SmallRuminants
UPDATE data_new SET data_var='Livestock::SmallRuminants[]::Housing::CFreeFactor::free_correction_factor' WHERE data_var='Livestock::SmallRuminants[]::Housing::free_correction_factor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

-- RoughageConsuming
UPDATE data_new SET data_var='Livestock::RoughageConsuming[]::Housing::CFreeFactor::free_correction_factor' WHERE data_var='Livestock::RoughageConsuming[]::Housing::free_correction_factor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

-- Poultry
UPDATE data_new SET data_var='Livestock::Poultry[]::Grazing::free_range' WHERE data_var='Livestock::Poultry[]::Outdoor::free_range'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
-- 0 data
--UPDATE data_new SET data_var='Livestock::Poultry[]::Excretion::dimensioning_barn' WHERE data_var='Livestock::Poultry[]::Housing::KArea::dimensioning_barn'
--       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');



--- Die folgenden Variablen waren im Kantonalmodell 4.1 verhanden und wurden
--- im Agrammon 6 Modell entfernt.

DELETE FROM data_new WHERE data_var in (
'Application::Slurry::Applrate::appl_rate',
'Application::Slurry::Applrate::dilution_parts_water',
'Application::Slurry::CfreeFactor::free_correction_factor',
'Application::Slurry::Cseason::appl_autumn_winter_spring',
'Application::Slurry::Cseason::appl_summer',
'Application::Slurry::Csoft::appl_evening',
'Application::Slurry::Csoft::appl_hotdays',
'Application::SolidManure::CincorpTime::incorp_gt3d',
'Application::SolidManure::CincorpTime::incorp_lw4h',
'Application::SolidManure::CincorpTime::incorp_lw8h',
'Application::SolidManure::Cseason::appl_autumn_winter_spring',
'Application::SolidManure::Cseason::appl_summer'
) AND data_dataset in (SELECT dataset_id FROM dataset where dataset_version='6.0' AND dataset_modelvariant = 'Kantonal_LU');


DELETE FROM data_new WHERE data_var in (
'Livestock::DairyCow[]::Excretion::CConcentrates::amount_summer',
'Livestock::DairyCow[]::Excretion::CConcentrates::amount_winter',
'Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_hay_summer',
'Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_pellets_summer',
'Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_silage_summer',
'Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_beets_winter',
'Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_grass_silage_winter',
'Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_pellets_winter',
'Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_maize_silage_winter',
'Livestock::DairyCow[]::Excretion::CFeedSummerRatio::share_potatoes_winter',
'Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_beets_winter',
'Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_grass_silage_winter',
'Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_pellets_winter',
'Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_maize_silage_winter',
'Livestock::DairyCow[]::Excretion::CFeedWinterRatio::share_potatoes_winter',
'Livestock::DairyCow[]::Outdoor:free_correction_factor',
'Livestock::OtherCattle[]::Outdoor:free_correction_factor',
'Livestock::Equides[]::Yard:free_correction_factor',
'PlantProduction::AgriculturalArea::agricultural_area',
'PlantProduction::MineralFertiliser::mineral_nitrogen_fertiliser_except_urea',
'PlantProduction::MineralFertiliser::mineral_nitrogen_fertiliser_urea'
) AND data_dataset in (SELECT dataset_id FROM dataset where dataset_version='6.0' AND dataset_modelvariant = 'Kantonal_LU');


DELETE FROM data_new WHERE data_var in (
'Livestock::DairyCow[]::Outdoor::free_correction_factor',
'Livestock::OtherCattle[]::Outdoor::free_correction_factor',
'Livestock::Equides[]::Yard::free_correction_factor',
'Livestock::FatteningPigs[]::Housing::Type::housing_type_LU',
'Livestock::FatteningPigs[]::Housing::Type::housing_type_SHL',
'Storage::Slurry[]::mixing_frequency',
'Storage::Slurry[]::EFLiquid::free_correction_factor'
'Storage::SolidManure::Poultry::free_correction_factor',
'Storage::SolidManure::Solid::free_correction_factor_cattle_manure',
'Storage::SolidManure::Solid::free_correction_factor_pig_manure',
'Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_air',
'Livestock::Pig[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_pigs',
'Livestock::Pig[]::Housing::Type::housing_type_LU',
'Livestock::Pig[]::Housing::Type::housing_type_SHL'
) AND data_dataset in (SELECT dataset_id FROM dataset where dataset_version='6.0' AND dataset_modelvariant = 'Kantonal_LU');
