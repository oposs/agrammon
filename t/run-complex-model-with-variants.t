use Test;
use Data::Dump::Tree;
use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::ModelCache;
use Agrammon::Model::Parameters;
use Agrammon::OutputFormatter::CSV;
use Agrammon::OutputFormatter::JSON;
use Agrammon::OutputFormatter::Text;
use Agrammon::TechnicalParser;

my $temp-dir = $*TMPDIR.add('agrammon_testing');

#| Model version and variants (dash doesn't work in Variant names)
my $model-version = 'hr-inclNOxExtendedWithFilters';
my $model-variants = (
    # # model version for web (Baugesuch Kanton Luzern)
    # 'Kantonal_LU',
    # model version for command line (no reports, extended variable output)
    'Single_extendedOutput',
    # # model version for command line (checking N/TAN flows)
    # 'Single_checkBalance',
    # # default model version for web (detailed reports, reduced variable output)
    # 'Single_default'
    );

#| Expected results
my $nh3-ntotal = 3157.775;
my $nh3-nanimalproduction = 3135.575;
my $nh3-napplication = 1351.033;
my $n-into-application = 7480.652;
my $tan-into-application = 3202.854;

my $filename = 'hr-inclNOxExtendedWithFilters-model-input.csv';
my $fh = open $*PROGRAM.parent.add("test-data/$filename");
my @datasets = Agrammon::DataSource::CSV.new().read($fh);
is @datasets.elems, 1, "Got the one expected data set from $filename to run";
$fh.close;

my $path = $*PROGRAM.parent.add("test-data/Models/$model-version/");

for $model-variants.values -> $variant {
    subtest "Variant $variant" => {

        my $model;
        lives-ok { $model = load-model-using-cache($temp-dir, $path, 'End', set($variant)) },
                "Load module End.nhd with variant $variant from $path";

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

        is (+%output-hash<Total><nh3_ntotal>).round(.001), $nh3-ntotal.round(.001),
                "Correct nh3_ntotal result: { (+%output-hash<Total><nh3_ntotal>).round(.001) }";
        is (+%output-hash<Total><nh3_nanimalproduction>).round(.001), $nh3-nanimalproduction.round(.001),
                "Correct nh3_nanimalproduction result: { (+%output-hash<Total><nh3_nanimalproduction>).round(.001) }";
        is (+%output-hash<Application><nh3_napplication>).round(.001), $nh3-napplication.round(.001),
                "Correct nh3_napplication result: { (+%output-hash<Application><nh3_napplication>).round(.001) }";
        is (+%output-hash<Storage><n_into_application>).round(.001), $n-into-application.round(.001),
                "Correct n_into_application result: { (+%output-hash<Storage><n_into_application>).round(.001) }";
        is (+%output-hash<Storage><tan_into_application>).round(.001), $tan-into-application.round(.001),
                "Correct tan_into_application result: { (+%output-hash<Storage><tan_into_application>).round(.001) }";


       # say "\nFluxSummaryLivestock=\n", output-as-text($model, $output, 'de', 'FluxSummaryLivestock,TANFlux', False);
       # say "\nFluxSummaryLivestock (Details)=\n", output-as-text($model, $output, 'de', 'FluxSummaryLivestock,TANFlux', True);
       # say "\nLivestockSummary (Details)=\n", output-as-text($model, $output, 'de', 'LivestockSummary', True);
       # say "\nnewStorage (Details)=\n", output-as-text($model, $output, 'de', 'newStorage', True);
       # say "\nnewStorage (Details)=\n", output-as-text($model, $output, 'de', 'check', True);

#        ddt "GUI: $print with filters=", output-for-gui($model, $output, True)<data>;
    }
}
done-testing;
