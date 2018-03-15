use v6;
use Agrammon::Inputs;
use Agrammon::DataSource::CSV;
use Test;

my $filename = 't/test-data/inputPlantproduction.csv';
my $fh = open $filename, :r, :!chomp
    or die "Couldn't open file $filename for reading";

my $ds = Agrammon::DataSource::CSV.new;
isa-ok $ds, Agrammon::DataSource::CSV, 'Is a DataSource::CSV';

my @datasets = $ds.read($fh);
is @datasets.elems, 2, 'Agrammon::DataSource::CSV.read() found 2 datasets';

subtest 'Data set 1', {
    isa-ok @datasets[0], Agrammon::Inputs, 'Correct type';
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

done-testing;
