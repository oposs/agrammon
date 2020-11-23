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

        # check balance in N and TAN flows
        # input = losses + remaining  
        if ($model-version eq "hr-inclNOxExtendedWithFilters") { 

            ### losses for both, TAN and N
            
            ## livestock
            my $losses-livestock-both = %output-hash<Livestock><n_excretion>.scale(0.0);
                my @outputs-livestock-both =
                    'nh3_nlivestock',       # nh3 loss from housing + yard + grazing
                    'n2_ngrazing',          # n2 loss from grazing (housing + yard -> storage)
                    'no_ngrazing',          # no loss from grazing (housing + yard -> storage)
                    'n2o_ngrazing',         # n2o loss from grazing (housing + yard -> storage)
                    'tan_remain_scrubber';  # nh3/tan remaining (vanishing) in air scrubber
                for @outputs-livestock-both -> $output {
                    $losses-livestock-both .= apply-pairwise(%output-hash<Livestock>{$output}, &infix:<+>, 0);
                }
            
            ## storage
            my $losses-storage-both = %output-hash<Livestock><n_excretion>.scale(0.0);
                # nxox losses from housing, yard and storage
                my @outputs-storage-both =
                    'n2_nhousing_and_storage',  # n2 loss from housing, yard and storage
                    'no_nhousing_and_storage',  # no loss from housing, yard and storage
                    'n2o_nhousing_and_storage'; # n2o loss from housing, yard and storage
                for @outputs-storage-both -> $output {
                    $losses-storage-both .= apply-pairwise(%output-hash<Livestock>{$output}, &infix:<+>, 0);
                }
                # nh3 loss from storage
                $losses-storage-both .= apply-pairwise(%output-hash<Storage><nh3_nstorage>, &infix:<+>, 0);
            
            ## application
            my $losses-application-both = %output-hash<Livestock><n_excretion>.scale(0.0);
                my @outputs-application-both =
                    'nh3_napplication',       # nh3 loss from housing + yard + grazing
                    'n2_napplication',          # n2 loss from application
                    'no_napplication',          # no loss from application
                    'n2o_napplication';         # n2o loss from application
                for @outputs-application-both -> $output {
                    $losses-application-both .= apply-pairwise(%output-hash<Application>{$output}, &infix:<+>, 0);
                }

            ### check ntot balance
            # N input
            my $balance-ntot = %output-hash<Livestock><n_excretion>;
            # N output livestock (N losses + N remaining)
                # both
                $balance-ntot .= apply-pairwise($losses-livestock-both, &infix:<->, 0);
                # N only
                $balance-ntot .= apply-pairwise(%output-hash<Livestock><n_remain_grazing>, &infix:<->, 0);
            # N output storage (N losses)
                # both
                $balance-ntot .= apply-pairwise($losses-storage-both, &infix:<->, 0);
            # N output application (N losses + N remaining)
                # both
                $balance-ntot .= apply-pairwise($losses-application-both, &infix:<->, 0);
                # N only
                $balance-ntot .= apply-pairwise(%output-hash<Application><n_remain_application>, &infix:<->, 0);
            # check balance for each animal category:
            for $balance-ntot.results-by-filter-group():all -> $res {
                is $res.value.round(.001), 0.0,
                    "Correct '{ $res.key.values }' balance: 0.0";
            }

            ### check tan balance
            # TAN input
            my $balance-tan = %output-hash<Livestock><tan_excretion>;
            # TAN output livestock (TAN losses + TAN remaining)
                # both
                $balance-tan .= apply-pairwise($losses-livestock-both, &infix:<->, 0);
                # TAN only
                $balance-tan .= apply-pairwise(%output-hash<Livestock><tan_remain_grazing>, &infix:<->, 0);
            # TAN output storage (TAN losses)
                # both
                $balance-tan .= apply-pairwise($losses-storage-both, &infix:<->, 0);
                # TAN only
                $balance-tan .= apply-pairwise(%output-hash<Storage><mineralization>, &infix:<+>, 0);
                $balance-tan .= apply-pairwise(%output-hash<Storage><immobilization>, &infix:<->, 0);
            # TAN output application (TAN losses + TAN remaining)
                # both
                $balance-tan .= apply-pairwise($losses-application-both, &infix:<->, 0);
                # TAN only
                $balance-tan .= apply-pairwise(%output-hash<Application><tan_remain_application>, &infix:<->, 0);
            # check balance for each animal category:
            for $balance-tan.results-by-filter-group():all -> $res {
                is $res.value.round(.001), 0.0,
                    "Correct '{ $res.key.values }' balance: 0.0";
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
