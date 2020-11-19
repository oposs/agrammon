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

for <hr-inclNOxExtended hr-inclNOxExtendedWithFilters> -> $model-version {
    subtest "Model $model-version" => {
        my $path = $*PROGRAM.parent.add("test-data/Models/$model-version/");
        my ($model, $params, $output);

        lives-ok { $model = load-model-using-cache($temp-dir, $path, 'End') },
                "Load module End.nhd from $path";
        lives-ok
                { $params = parse-technical($*PROGRAM.parent.add("test-data/Models/$model-version/technical.cfg")
                .slurp) },
                'Parsed technical file';
        isa-ok $params, Agrammon::Model::Parameters, 'Correct type for technical data';
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

        # check balance for each "Stufe" (livestock, storage, application)
        # input = output + loss + remaining  
        if ($model-version eq "hr-inclNOxExtendedWithFilters") { 
            ### check livestock ntot balance
            my $balance-livestock-ntot =
                # get n into housing + yard + grazing 
                %output-hash<Livestock><n_excretion>.apply-pairwise(
                    # subtract nh3 loss from housing + yard + grazing
                    %output-hash<Livestock><nh3_nlivestock>, &infix:<->, 0
                ).apply-pairwise(
                    # subtract n2 loss from grazing (housing + yard -> storage)
                    %output-hash<Livestock><n2_ngrazing>, &infix:<->, 0
                ).apply-pairwise(
                    # subtract no loss from grazing (housing + yard -> storage)
                    %output-hash<Livestock><no_ngrazing>, &infix:<->, 0
                ).apply-pairwise(
                    # subtract n2o loss from grazing (housing + yard -> storage)
                    %output-hash<Livestock><n2o_ngrazing>, &infix:<->, 0
                ).apply-pairwise(
                    # subtract ntot remaining in soil from grazing
                    %output-hash<Livestock><n_remain_grazing>, &infix:<->, 0
                ).apply-pairwise(
                    # subtract ntot remaining (vanishing) in air scrubber
                    %output-hash<Livestock><tan_remain_scrubber>, &infix:<->, 0
                ).apply-pairwise(
                    # subtract ntot out of housing + yard + grazing
                    %output-hash<Livestock><n_out_livestock>, &infix:<->, 0
                );
            for $balance-livestock-ntot.results-by-filter-group -> $res {
                # silent unless test fails:
                if ($res.value.round(.001) ne 0.0) {
                    is $res.value.round(.001), 0.0,
                        "Correct '{ $res.key.values }' balance: 0.0";
                }
            }

        }

       # say "\nFluxSummaryLivestock=\n", output-as-text($model, $output, 'de', 'FluxSummaryLivestock,TANFlux', False);
       # say "\nFluxSummaryLivestock (Details)=\n", output-as-text($model, $output, 'de', 'FluxSummaryLivestock,TANFlux', True);
       # say "\nLivestockSummary (Details)=\n", output-as-text($model, $output, 'de', 'LivestockSummary', True);
       # say "\nnewStorage (Details)=\n", output-as-text($model, $output, 'de', 'newStorage', True);
       # say "\nnewStorage (Details)=\n", output-as-text($model, $output, 'de', 'check', True);

#        ddt "GUI: $print with filters=", output-for-gui($model, $output, :include-filters)<data>;
    }
}
done-testing;
