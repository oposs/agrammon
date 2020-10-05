use Test;
use Data::Dump::Tree;
use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::ModelCache;
use Agrammon::Model::Parameters;
use Agrammon::OutputFormatter::CSV;
use Agrammon::OutputFormatter::GUI;
use Agrammon::OutputFormatter::Text;
use Agrammon::TechnicalParser;

my $temp-dir = $*TMPDIR.add('agrammon_testing');

#| Expected results
my $nh3-ntotal = 3028.087;
my $nh3-nanimalproduction = 3028.087;
my $nh3-napplication = 1358.701;

# my $filename = 'hr-inclNOxExtendedWithFilters-model-input.csv';
my $filename = 'hr-inclNOxExtendedWithFilters-model-input2.csv';
my $fh = open $*PROGRAM.parent.add("test-data/$filename");
my @datasets = Agrammon::DataSource::CSV.new().read($fh);
is @datasets.elems, 1, "Got the one expected data set from $filename to run";
$fh.close;

for <hr-inclNOxExtended hr-inclNOxExtendedWithFilters> -> $model-version {
    subtest "Model $model-version" => {
        my $path = $*PROGRAM.parent.add("test-data/Models/$model-version/");
        my $model;
        lives-ok { $model = load-model-using-cache($temp-dir, $path, 'End') },
                "Load module End.nhd from $path";

        my $params;
        lives-ok
                { $params = parse-technical($*PROGRAM.parent.add("test-data/Models/$model-version/technical.cfg")
                .slurp) },
                'Parsed technical file';
        isa-ok $params, Agrammon::Model::Parameters, 'Correct type for technical data';

        my $output;
        lives-ok
                {
                    $output = $model.run(
                            input => @datasets[0],
                            technical => %($params.technical.map(-> %module {
                                %module.keys[0] => %(%module.values[0].map({ .name => .value }))
                            }))
                    )
                },
                'Successfully executed model';
        my %output-hash = $output.get-outputs-hash;

        is %output-hash<Total><nh3_ntotal>.round(.001), $nh3-ntotal.round(.001),
                "Correct nh3_ntotal result: { %output-hash<Total><nh3_ntotal>.round(.001) }";
        is %output-hash<Total><nh3_nanimalproduction>.round(.001), $nh3-nanimalproduction.round(.001),
                "Correct nh3_nanimalproduction result: { %output-hash<Total><nh3_nanimalproduction>.round(.001) }";
        is (+%output-hash<Application><nh3_napplication>).round(.001), $nh3-napplication.round(.001),
                "Correct nh3_napplication result: { (+%output-hash<Application><nh3_napplication>).round(.001) }";

       # say "\nFluxSummaryLivestock=\n", output-as-text($model, $output, 'de', 'FluxSummaryLivestock,TANFlux', False);
       # say "\nFluxSummaryLivestock=\n", output-as-text($model, $output, 'de', 'FluxSummaryLivestock', True);
       # say "\nFluxSummaryLivestock (Details)=\n", output-as-text($model, $output, 'de', 'FluxSummaryLivestock,TANFlux', True);
       # say "\nLivestockSummary (Details)=\n", output-as-text($model, $output, 'de', 'LivestockSummary', True);
       # say "\nnewStorage (Details)=\n", output-as-text($model, $output, 'de', 'newStorage,storage_check', True);
       say "\nnewStorage (Details)=\n", output-as-text($model, $output, 'de', 'newStorage,storage_check', True);
       # say "\nnewStorage (Details)=\n", output-as-text($model, $output, 'de', '3a', True);
       # say "\ncheck pigs (Details)=\n", output-as-text($model, $output, 'de', 'check_pigs', True);
       # say "\ncheck pigs (Details)=\n", output-as-text($model, $output, 'de', 'check_pigs_housing', True);
       # say "\ncheck pigs (Details)=\n", output-as-text($model, $output, 'de', '7', True);
       # say "\ncheck pigs (Details)=\n", output-as-text($model, $output, 'de', 'dummy', True);
       # ddt "\ncheck pigs (Details)=\n", output-as-text($model, $output, 'de', 'check_pigs_housing', True);

       # ddt "GUI: FluxSummaryLivestock=", output-for-gui($model, $output)<data>[0];
    }
}
done-testing;
