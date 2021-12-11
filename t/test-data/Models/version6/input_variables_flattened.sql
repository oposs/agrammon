-- DairyCow, OtherCattle
DELETE FROM data_new WHERE (data_var LIKE 'Livestock::DairyCow[]::Housing::Floor%_toothed scrapper running over a grooved floor' OR data_var LIKE 'Livestock::OtherCattle[]::Housing::Floor%_toothed scrapper running over a grooved floor')
AND data_dataset IN (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

-- DairyCow
UPDATE data_new SET data_var='Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor_flattened00_none' WHERE data_var='Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows_flattened00_none'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor_flattened01_raised feeding stands' WHERE data_var='Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows_flattened01_raised feeding stands'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor_flattened02_floor with cross slope and collection gutter' WHERE data_var='Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows_flattened02_floor with cross slope and collection gutter'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor_flattened03_floor with cross slope and collection gutter and raised feeding stands' WHERE data_var='Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows_flattened03_floor with cross slope and collection gutter and raised feeding stands'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard_flattened00_solid floor' WHERE data_var='Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_SHL_flattened00_solid floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard_flattened01_unpaved floor' WHERE data_var='Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_SHL_flattened01_unpaved floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard_flattened02_perforated floor' WHERE data_var='Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_SHL_flattened02_perforated floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard_flattened03_paddock or pasture used as exercise yard' WHERE data_var='Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_SHL_flattened03_paddock or pasture used as exercise yard'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::exercise_yard_flattened00_not available' WHERE data_var='Livestock::DairyCow[]::Yard::exercise_yard_flattened00_not available'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::exercise_yard_flattened01_available roughage is not supplied in the exercise yard' WHERE data_var='Livestock::DairyCow[]::Yard::exercise_yard_flattened01_available roughage is not supplied in the exercise yard'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::exercise_yard_flattened02_available roughage is partly supplied in the exercise yard' WHERE data_var='Livestock::DairyCow[]::Yard::exercise_yard_flattened02_available roughage is partly supplied in the exercise yard'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::exercise_yard_flattened03_available roughage is exclusively supplied in the exercise yard' WHERE data_var='Livestock::DairyCow[]::Yard::exercise_yard_flattened03_available roughage is exclusively supplied in the exercise yard'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');


-- OtherCattle
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor_flattened00_none' WHERE data_var='Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle_flattened00_none'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor_flattened01_raised feeding stands' WHERE data_var='Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle_flattened01_raised feeding stands'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor_flattened02_floor with cross slope and collection gutter' WHERE data_var='Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle_flattened02_floor with cross slope and collection gutter'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor_flattened03_floor with cross slope and collection gutter and raised feeding stands' WHERE data_var='Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle_flattened03_floor with cross slope and collection gutter and raised feeding stands'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard_flattened00_solid floor' WHERE data_var='Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_SHL_flattened00_solid floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard_flattened01_unpaved floor' WHERE data_var='Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_SHL_flattened01_unpaved floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard_flattened02_perforated floor' WHERE data_var='Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_SHL_flattened02_perforated floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard_flattened03_paddock or pasture used as exercise yard' WHERE data_var='Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_SHL_flattened03_paddock or pasture used as exercise yard'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::exercise_yard_flattened00_not available' WHERE data_var='Livestock::OtherCattle[]::Yard::exercise_yard_flattened00_not available'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::exercise_yard_flattened01_available roughage is not supplied in the exercise yard' WHERE data_var='Livestock::OtherCattle[]::Yard::exercise_yard_flattened01_available roughage is not supplied in the exercise yard'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::exercise_yard_flattened02_available roughage is partly supplied in the exercise yard' WHERE data_var='Livestock::OtherCattle[]::Yard::exercise_yard_flattened02_available roughage is partly supplied in the exercise yard'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::exercise_yard_flattened03_available roughage is exclusively supplied in the exercise yard' WHERE data_var='Livestock::OtherCattle[]::Yard::exercise_yard_flattened03_available roughage is exclusively supplied in the exercise yard'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

-- Pig

UPDATE data_new SET data_val='none' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_floor' AND data_val!='flattened'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('RegionalSHL') );
UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_floor_flattened00_none', data_val=100 WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_pigs_flattened00_none'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
DELETE FROM data_new WHERE data_var LIKE 'Livestock::Pig[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_pigs_flattened%'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');


UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_air_flattened00_none' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_air_flattened00_none'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_air_flattened01_low impuls air supply' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_air_flattened01_low impuls air supply'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

-- Fattening Pigs

UPDATE data_new SET data_val='none' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor' AND data_val!='flattened'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0' AND dataset_model IN ('RegionalSHL') );
UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor_flattened00_none', data_val=100 WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_fattening_pigs_slurry_channel_flattened00_none'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
DELETE FROM data_new WHERE data_var LIKE 'Livestock::FatteningPigs[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_fattening_pigs_slurry_channel_flattened%'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_air_flattened00_none' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_fattening_pigs_air_flattened00_none'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_air_flattened01_low impuls air supply' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_fattening_pigs_air_flattened01_low impuls air supply'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

-- Poultry

UPDATE data_new SET data_var='Livestock::Poultry[]::Grazing::free_range_flattened00_yes' WHERE data_var='Livestock::Poultry[]::Outdoor::free_range_flattened00_yes'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::Poultry[]::Grazing::free_range_flattened01_no' WHERE data_var='Livestock::Poultry[]::Outdoor::free_range_flattened01_no'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

-- Equides

UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::floor_properties_exercise_yard_flattened00_solid floor' WHERE data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard_SHL_flattened00_solid floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::floor_properties_exercise_yard_flattened01_unpaved floor' WHERE data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard_SHL_flattened01_unpaved floor'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::floor_properties_exercise_yard_flattened02_paddock or pasture used as exercise yard' WHERE data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard_SHL_flattened02_paddock or pasture used as exercise yard'
       AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
