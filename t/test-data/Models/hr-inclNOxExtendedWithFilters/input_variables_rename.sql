# DairyCow
UPDATE data_new SET data_var='Livestock::DairyCow[]::Excretion::dimensioning_barn' WHERE data_var='Livestock::DairyCow[]::Housing::Type::dimensioning_barn';
UPDATE data_new SET data_var='Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor' WHERE data_var='Livestock::DairyCow[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_dairy_cows';
UPDATE data_new SET data_var='Livestock::DairyCow[]::Housing::Floor::mitigation_housing_floor' WHERE data_var='Livestock::DairyCow[]::Housing::Floor::mitigation_options_for_housing_systems_for_dairy_cows_floor';
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard' WHERE data_var='Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_SHL';
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::floor_properties_exercise_yard' WHERE data_var='Livestock::DairyCow[]::Yard::floor_properties_exercise_yard_LU';
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::grazing_days' WHERE data_var='Livestock::DairyCow[]::GrazingInput::grazing_days';
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::grazing_hours' WHERE data_var='Livestock::DairyCow[]::GrazingInput::grazing_hours';
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::yard_days' WHERE data_var='Livestock::DairyCow[]::Yard::yard_days';
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::exercise_yard' WHERE data_var='Livestock::DairyCow[]::Yard::exercise_yard';
UPDATE data_new SET data_var='Livestock::DairyCow[]::Outdoor::free_correction_factor' WHERE data_var='Livestock::DairyCow[]::Yard::free_correction_factor';
# OtherCattle
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Excretion::dimensioning_barn' WHERE data_var='Livestock::OtherCattle[]::Housing::Type::dimensioning_barn';
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor' WHERE data_var='Livestock::OtherCattle[]::Housing::Floor::UNECE_category_1_mitigation_options_for_housing_systems_for_other_cattle';
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Housing::Floor::mitigation_housing_floor' WHERE data_var='Livestock::OtherCattle[]::Housing::Floor::mitigation_options_for_housing_systems_for_other_cattle_floor';
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard' WHERE data_var='Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_SHL';
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::floor_properties_exercise_yard' WHERE data_var='Livestock::OtherCattle[]::Yard::floor_properties_exercise_yard_LU';
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::grazing_days' WHERE data_var='Livestock::OtherCattle[]::GrazingInput::grazing_days';
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::grazing_hours' WHERE data_var='Livestock::OtherCattle[]::GrazingInput::grazing_hours';
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::yard_days' WHERE data_var='Livestock::OtherCattle[]::Yard::yard_days';
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::exercise_yard' WHERE data_var='Livestock::OtherCattle[]::Yard::exercise_yard';
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Outdoor::free_correction_factor' WHERE data_var='Livestock::OtherCattle[]::Yard::free_correction_factor';
# FatteningPigs
UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Excretion::dimensioning_barn' WHERE data_var='Livestock::FatteningPigs[]::Housing::KArea::dimensioning_barn';
UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_fattening_pigs';
UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_fattening_pigs_slurry_channel';
UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_air' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_fattening_pigs_air';
# Pig
UPDATE data_new SET data_var='Livestock::Pig[]::Excretion::dimensioning_barn' WHERE data_var='Livestock::Pig[]::Housing::KArea::dimensioning_barn';
UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_floor' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_pigs';
UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_floor' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_slurry_channel';
UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_air' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_air';
# Equides
UPDATE data_new SET data_var='Livestock::Equides[]::Housing::CFreeFactor::free_correction_factor' WHERE data_var='Livestock::Equides[]::Housing::free_correction_factor';
UPDATE data_new SET data_var='Livestock::Equides[]::GrazingInput::grazing_days' WHERE data_var='Livestock::Equides[]::Grazing::grazing_days';
UPDATE data_new SET data_var='Livestock::Equides[]::GrazingInput::grazing_hours' WHERE data_var='Livestock::Equides[]::Grazing::grazing_hours';
UPDATE data_new SET data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard' WHERE data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard_SHL';
UPDATE data_new SET data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard' WHERE data_var='Livestock::Equides[]::Yard::floor_properties_exercise_yard_LU';
# SmallRuminants
UPDATE data_new SET data_var='Livestock::SmallRuminants[]::Housing::CFreeFactor::free_correction_factor' WHERE data_var='Livestock::SmallRuminants[]::Housing::free_correction_factor';
# RoughageConsuming
UPDATE data_new SET data_var='Livestock::RoughageConsuming[]::Housing::CFreeFactor::free_correction_factor' WHERE data_var='Livestock::RoughageConsuming[]::Housing::free_correction_factor';
#Poultry
UPDATE data_new SET data_var='Livestock::Poultry[]::Grazing::free_range' WHERE data_var='Livestock::Poultry[]::Outdoor::free_range';
UPDATE data_new SET data_var='Livestock::Poultry[]::Excretion::dimensioning_barn' WHERE data_var='Livestock::Poultry[]::Housing::KArea::dimensioning_barn';
