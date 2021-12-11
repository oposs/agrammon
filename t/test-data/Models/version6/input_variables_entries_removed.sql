DELETE FROM data_new WHERE (data_var LIKE 'Livestock::FatteningPigs[]::Housing::MitigationOptions%' OR data_var LIKE 'Livestock::Pig[]::Housing::MitigationOptions%') 
AND data_val IN
('with_scraper_concrete_slats', 'with_scraper_metal_slats',
'with_flush_channels_no_areation', 'with_flush_gutters_tubes_no_areation',
'with_channels_slanted_walls_concrete_slats',
'with_channel_slanted_walls_metal_slats', 'with_flush_channels_areation',
'with_flush_gutters_tubes_areation')
AND data_dataset IN (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');

DELETE FROM data_new WHERE (data_var LIKE 'Livestock::DairyCow[]::Housing::Floor%' OR data_var LIKE 'Livestock::OtherCattle[]::Housing::Floor%')
AND data_val = 'toothed_scrapper_running_over_a_grooved_floor'
AND data_dataset IN (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');


-- flattened
DELETE FROM data_new WHERE (data_var LIKE 'Livestock::DairyCow[]::Housing::Floor%_toothed scrapper running over a grooved floor' OR data_var LIKE 'Livestock::OtherCattle[]::Housing::Floor%_toothed scrapper running over a grooved floor')
AND data_dataset IN (SELECT dataset_id FROM dataset WHERE dataset_version = '6.0');
