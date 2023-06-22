use v6;
use Agrammon::Inputs;
use Agrammon::DataSource::CSV;
use Test;

{
    my $filename = 't/test-data/inputPlantproduction.csv';
    my $fh = open $filename, :r, :!chomp
        or die "Couldn't open file $filename for reading";
    LEAVE $fh.close;

    my $ds = Agrammon::DataSource::CSV.new;
    isa-ok $ds, Agrammon::DataSource::CSV, 'Is a DataSource::CSV';

    my @datasets = $ds.read($fh);
    is @datasets.elems, 2, 'Agrammon::DataSource::CSV.read() found 2 datasets';

    subtest 'Data set 1', {
        isa-ok @datasets[0], Agrammon::Inputs, 'Correct type';
        is @datasets[0].simulation-name, 'TEST', 'Correct simulation name';
        is @datasets[0].dataset-id, 1, 'Correct data set ID';
        is-deeply @datasets[0].input-hash-for('PlantProduction::AgriculturalArea'),
            { agricultural_area => 20 },
            'Correct data for PlantProduction::AgriculturalArea';
        is-deeply @datasets[0].input-hash-for('PlantProduction::MineralFertiliser'),
            {
                mineral_nitrogen_fertiliser_urea => 0,
                mineral_nitrogen_fertiliser_except_urea => 150
            },
            'Correct data for PlantProduction::MineralFertiliser';
        is-deeply @datasets[0].input-hash-for('PlantProduction::RecyclingFertiliser'),
        {
            compost => 0,
            solid_digestate => 0,
            liquid_digestate => 0
        },
        'Correct data for PlantProduction::RecyclingFertiliser';
    }

    subtest 'Data set 2', {
        isa-ok @datasets[1], Agrammon::Inputs, 'Correct type';
        is @datasets[1].simulation-name, 'TEST', 'Correct simulation name';
        is @datasets[1].dataset-id, 2, 'Correct data set ID';
        is-deeply @datasets[1].input-hash-for('PlantProduction::AgriculturalArea'),
        { agricultural_area => 40 },
        'Correct data for PlantProduction::AgriculturalArea';
        is-deeply @datasets[1].input-hash-for('PlantProduction::MineralFertiliser'),
        {
            mineral_nitrogen_fertiliser_urea => 10,
            mineral_nitrogen_fertiliser_except_urea => 150
        },
        'Correct data for PlantProduction::MineralFertiliser';
        is-deeply @datasets[1].input-hash-for('PlantProduction::RecyclingFertiliser'),
        {
            compost => 10,
            solid_digestate => 10,
            liquid_digestate => 10
        },
        'Correct data for PlantProduction::RecyclingFertiliser';
    }
}

{
    my $filename = 't/test-data/MultiInstanceInput.csv';
    my $fh = open $filename, :r, :!chomp
            or die "Couldn't open file $filename for reading";
    LEAVE $fh.close;

    my $ds = Agrammon::DataSource::CSV.new;
    isa-ok $ds, Agrammon::DataSource::CSV, 'Is a DataSource::CSV';

    my @datasets = $ds.read($fh);
    is @datasets.elems, 2, 'Agrammon::DataSource::CSV.read() found 2 datasets';

    subtest 'Data set 1', {
        isa-ok @datasets[0], Agrammon::Inputs, 'Correct type';
        is @datasets[0].simulation-name, '2010v2.1_20120425', 'Correct simulation name';
        is @datasets[0].dataset-id, 2, 'Correct data set ID';
        my @input-list = @datasets[0].inputs-list-for('Livestock::DairyCow');
        is @input-list.elems, 2, 'Have 2 dairy cow inputs';
        is-deeply @input-list[0].input-hash-for('Livestock::DairyCow::Excretion::CConcentrates'),
                { amount_summer => 2.5, amount_winter => 2.5 },
                'Correct Livestock::DairyCow::Excretion::CConcentrates input';
        is-deeply @input-list[0].input-hash-for('Livestock::DairyCow::Excretion::CFeedSummerRatio'),
                { share_hay_summer => 100, share_maize_pellets_summer => 0 },
                'Correct Livestock::DairyCow::Excretion::CFeedSummerRatio input';
        is-deeply @input-list[0].input-hash-for('Livestock::DairyCow'),
                { moo => 1 },
                'Correct Livestock::DairyCow input';
        is-deeply @input-list[1].input-hash-for('Livestock::DairyCow::Excretion::CConcentrates'),
                { amount_summer => 3.5, amount_winter => 3.0 },
                'Correct Livestock::DairyCow::Excretion::CConcentrates input';
        is-deeply @input-list[1].input-hash-for('Livestock::DairyCow::Excretion::CFeedSummerRatio'),
                { share_hay_summer => 90, share_maize_pellets_summer => 10 },
                'Correct Livestock::DairyCow::Excretion::CFeedSummerRatio input';
        is-deeply @input-list[1].input-hash-for('Livestock::DairyCow'),
                { moo => 3 },
                'Correct Livestock::DairyCow input';
    }


    subtest 'Data set 2', {
        isa-ok @datasets[1], Agrammon::Inputs, 'Correct type';
        is @datasets[1].simulation-name, '2010v2.1_20120425', 'Correct simulation name';
        is @datasets[1].dataset-id, 18, 'Correct data set ID';
        my @input-list = @datasets[1].inputs-list-for('Livestock::DairyCow');
        is @input-list.elems, 2, 'Have 2 dairy cow inputs';
        is-deeply @input-list[0].input-hash-for('Livestock::DairyCow::Excretion::CConcentrates'),
                { amount_summer => 4, amount_winter => 4 },
                'Correct Livestock::DairyCow::Excretion::CConcentrates input';
        is-deeply @input-list[0].input-hash-for('Livestock::DairyCow::Excretion::CFeedSummerRatio'),
                { share_hay_summer => 100, share_maize_pellets_summer => 0 },
                'Correct Livestock::DairyCow::Excretion::CFeedSummerRatio input';
        is-deeply @input-list[0].input-hash-for('Livestock::DairyCow'),
                { moo => 5 },
                'Correct Livestock::DairyCow input';
        is-deeply @input-list[1].input-hash-for('Livestock::DairyCow::Excretion::CConcentrates'),
                { amount_summer => 4, amount_winter => 4 },
                'Correct Livestock::DairyCow::Excretion::CConcentrates input';
        is-deeply @input-list[1].input-hash-for('Livestock::DairyCow::Excretion::CFeedSummerRatio'),
                { share_hay_summer => 10, share_maize_pellets_summer => 90 },
                'Correct Livestock::DairyCow::Excretion::CFeedSummerRatio input';
        is-deeply @input-list[1].input-hash-for('Livestock::DairyCow'),
                { moo => 7 },
                'Correct Livestock::DairyCow input';
    }
}

done-testing;
