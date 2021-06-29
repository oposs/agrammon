use v6;
use JSON::Fast;
use Test;

use Agrammon::Inputs;
use Agrammon::DataSource::JSON;

my $filename = 't/test-data/inputs-version6.json';

my $inputs;
subtest "Load inputs from JSON" => {
    ok my $input-data = $filename.IO.slurp, "Read JSON file";
    isa-ok my $data-source = Agrammon::DataSource::JSON.new, Agrammon::DataSource::JSON,
    'Is a Agrammon::DataSource::JSON';
    ok $inputs = $data-source.load('Agrammon Test', 'Version6', $input-data), "Load inputs";
    note $inputs.all-inputs.keys.join("\n");
    is $inputs.all-inputs.keys.elems, 15, "Found 15 modules";
}

subtest "Single-instance data" => {
    is $inputs.all-inputs<PlantProduction::RecyclingFertiliser><compost>, 10, "Found right amount of compost";
    is $inputs.all-inputs<Application::Slurry::Ctech><share_deep_injection>, 10, "Found right amount of deep injection";
}

subtest "Multi-instance data" => {
    subtest "Livestock::DairyCow" => {
        is $inputs.all-inputs<Livestock::DairyCow>.elems, 1, "Found 1 Livestock::DairyCow instance";
        is $inputs.all-inputs<Livestock::DairyCow>[0].keys[0], "DC_Ex1", "Found correct instance name";
        is $inputs.all-inputs<Livestock::DairyCow>[0].values[0]<Livestock::DairyCow::Excretion><animals>, 10,
                "Found correct number of animals";
    }
    subtest "Storage::Slurry" => {
        is $inputs.all-inputs<Storage::Slurry>[0].keys[0], "Store Liquid 1", "Found correct instance name";
        is $inputs.all-inputs<Storage::Slurry>[0].values[0]<Storage::Slurry><depth>, 4, "Found correct depth";
    }
}

done-testing;
