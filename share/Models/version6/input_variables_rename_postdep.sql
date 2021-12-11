-- DairyCow
UPDATE data_new SET data_var='Livestock::DairyCow[]::Excretion::animals' WHERE data_var='Livestock::DairyCow[]::Excretion::dairy_cows'
   AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version='6.0');
-- FatteningPigs
UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Excretion::animals' WHERE data_var='Livestock::FatteningPigs[]::Excretion::fattening_pigs'
   AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version='6.0');
-- Pig
UPDATE data_new SET data_var='Livestock::Pig[]::Excretion::animals' WHERE data_var='Livestock::Pig[]::Excretion::pigs'
   AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version='6.0');

-- Equides
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::grazing_hours' WHERE data_var='Livestock::Equides[]::GrazingInput::grazing_hours'
   AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version='6.0');
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::grazing_days' WHERE data_var='Livestock::Equides[]::GrazingInput::grazing_days'
   AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version='6.0');

UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::yard_hours' WHERE data_var='Livestock::Equides[]::Yard::yard_hours'
   AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version='6.0');
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::yard_days' WHERE data_var='Livestock::Equides[]::Yard::yard_days'
   AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version='6.0');
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::floor_properties_exercise_yard' WHERE data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard'
   AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version='6.0');

-- ?if !Kantonal_LU:
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::free_correction_factor' WHERE data_var='Livestock::Equides[]::Yard::free_correction_factor'
   AND data_dataset in (SELECT dataset_id FROM dataset WHERE dataset_version='6.0' AND dataset_modelvariant!='Kantonal_LU' AND dataset_modelvariant!='UNKNOWN');
