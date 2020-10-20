UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_fattening_pigs';
UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_floor_LU' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_fattening_pigs_slurry_channel';
UPDATE data_new SET data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_housing_air' WHERE data_var='Livestock::FatteningPigs[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_fattening_pigs_air';
UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_floor' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::UNECE_category_1_mitigation_options_for_housing_systems_for_pigs';
UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_floor_LU' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_slurry_channel';
UPDATE data_new SET data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_housing_air' WHERE data_var='Livestock::Pig[]::Housing::MitigationOptions::mitigation_options_for_housing_systems_for_pigs_air';
UPDATE data_new SET data_var='Livestock::Equides[]::Housing::CFreeFactor::free_correction_factor' WHERE data_var='Livestock::Equides[]::Housing::free_correction_factor';
UPDATE data_new SET data_var='Livestock::RoughageConsuming[]::Housing::CFreeFactor::free_correction_factor' WHERE data_var='Livestock::RoughageConsuming[]::Housing::free_correction_factor';
UPDATE data_new SET data_var='Livestock::SmallRuminants[]::Housing::CFreeFactor::free_correction_factor' WHERE data_var='Livestock::SmallRuminants[]::Housing::free_correction_factor';
UPDATE data_new SET data_var='Livestock::OtherCattle[]::Housing::KArea::dimensioning_barn' WHERE data_var='Livestock::OtherCattle[]::Housing::Type::dimensioning_barn';

-- doesn't work (duplicates)
--UPDATE data_new SET data_var='Livestock::DairyCow[]::Housing::KArea::dimensioning_barn' WHERE data_var='Livestock::DairyCow[]::Housing::Type::dimensioning_barn';
