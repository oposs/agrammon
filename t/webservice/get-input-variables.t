use v6;
use Agrammon::Config;
use Agrammon::Model;
use Agrammon::Web::Service;
use Agrammon::Web::SessionUser;
use Test;

plan 4;

if %*ENV<AGRAMMON_UNIT_TEST> {
    skip-rest 'Not a unit test';
    exit;
}

if %*ENV<GITHUB_ACTIONS> {
    skip-rest('Not set up for GitHub Actions yet');
    exit;
}

    my $path = $*PROGRAM.parent.add('../test-data/Models/hr-inclNOx/');
#    my $top = 'PlantProduction';
    my $top = 'Total';
#    my $top = 'Livestock';
    my $model = Agrammon::Model.new(path => $path);
    lives-ok { $model.load($top) }, "Loaded $top";

    my %input-hash = $model.get-input-variables;
    %input-hash<dataset> = 'TEST';
    is-deeply %input-hash.keys.sort, qw|dataset graphs inputs reports| , "Input hash has expected keys";

    subtest "input variables" => {
        with %input-hash<inputs> -> @module-inputs {
            for @module-inputs -> @inputs {
                for @inputs -> $input {
                    my $var    = $input<variable>;
                    if $var ~~ /\:\:dairy_cows/ {
                        is-deeply $input.keys.sort, qw|branch defaults gui help labels models options optionsLang order type units validator variable|,
                        "$var has expected keys";
                        subtest "$var" => {
                            is $input<branch>, 'false', 'branch is false';
                            is-deeply $input<defaults>, %( calc => Any, gui => Any), 'defaults as expected';
                            is-deeply $input<gui>, %("de" =>"Tierhaltung::Milchkühe[]", "en" => "Livestock::DairyCow[]", "fr" => "Production animale::Vaches latière[]"), 'gui as expected';
                            is-deeply $input<help>, %("de" => "<p>Tatsächliche Anzahl Tiere im Stall.<\/p>", "en" => "<p>Actual number of animals in the barn.<\/p>", "fr" => "<p>Nombre effectif d’animaux dans la stabulation.<\/p>"), 'help as expected';
                            is $input<type>, 'integer', 'type is integer';
                            is-deeply $input<labels>, %("de" => "Anzahl Tiere", "en" => "Number of animals", "fr" => "Nombre d'animaux"), 'labels as expected';
                            is $input<models>, @("all"), 'models is ["all"]';
                            is $input<options>.elems, 0, 'options is empty';
                            is $input<optionsLang>.elems, 0, 'optionsLang is empty';
                            is $input<order>, 500000, 'order is 500000';
                            is-deeply $input<units>, %("de" => "-", "en" => "-", "fr" => "-"), 'units as expected';
                            is-deeply $input<validator>, %( args => ["0"], name => "ge"), "validator as expected";
                            is $input<variable>, 'Livestock::DairyCow[]::Excretion::dairy_cows', 'variable as expected'
                        }
                    }
                }
            }
        }
    };

    subtest "graphs and reports" => {
        my @graphs = %input-hash<graphs>;
#        dd @graphs;
        my %graph = @graphs[0];
        is-deeply %graph.keys.sort, qw|_order data name selector type|, "First graph has expected keys";
        is %graph<type>, 'bar', "Graph has correct type";

        my @reports = %input-hash<reports>;
        my %report = @reports[0];
        is-deeply %report.keys.sort, qw|_order data name selector type|, "First report has expected keys";
        is %report<type>, 'report', "Report has correct type";

    }


done-testing;
