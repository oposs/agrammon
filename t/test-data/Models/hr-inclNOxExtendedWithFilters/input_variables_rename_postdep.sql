# DairyCow
UPDATE data_new SET data_var='Livestock::DairyCow[]::Excretion::animals' WHERE data_var='Livestock::DairyCow[]::Excretion::dairy_cows';
# FatteningPigs
UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Excretion::animals' WHERE data_var='Livestock::FatteningPigs[]::Excretion::fattening_pigs';
# Pig
UPDATE data_new SET data_var='Livestock::Pig[]::Excretion::animals' WHERE data_var='Livestock::Pig[]::Excretion::pigs';
# Equides
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::grazing_hours' WHERE data_var='Livestock::Equides[]::GrazingInput::grazing_hours';
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::grazing_days' WHERE data_var='Livestock::Equides[]::GrazingInput::grazing_days';
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::yard_hours' WHERE data_var='Livestock::Equides[]::Yard::yard_hours';
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::yard_days' WHERE data_var='Livestock::Equides[]::Yard::yard_days';
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::floor_properties_exercise_yard' WHERE data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard';
# ?if !Kantonal_LU:
UPDATE data_new SET data_var='Livestock::Equides[]::Outdoor::free_correction_factor' WHERE data_var='Livestock::Equides[]::Yard::free_correction_factor';
