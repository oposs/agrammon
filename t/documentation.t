use Test;
use Data::Dump::Tree;
use Agrammon::DataSource::CSV;
use Agrammon::Documentation;
use Agrammon::Model;
use Agrammon::Model::Parameters;
use Agrammon::OutputFormatter::CSV;
use Agrammon::TechnicalParser;

my $model-version = 'hr-inclNOxExtendedWithFilters';
my $path = $*PROGRAM.parent.add("test-data/Models/$model-version/");
my $model = Agrammon::Model.new(:$path);
lives-ok { $model.load('Total') }, "Could load module Total from $path";
#lives-ok { $model.load('Livestock::DairyCow') }, "Could load module Livestock::DairyCow from $path";

my $params;
lives-ok
    { $params = parse-technical($*PROGRAM.parent.add("test-data/Models/$model-version/technical.cfg").slurp) },
    'Parsed technical file';
isa-ok $params, Agrammon::Model::Parameters, 'Correct type for technical data';

my $latex;
lives-ok { $latex = create-latex-source(
        'Model name',
        $model,
        technical => %($params.technical.map(-> %module {
            %module.keys[0] => %(%module.values[0].map({ .name => .value }))
        }))
    );
}, "Create LaTeX";

ok $latex ~~ / '\begin{document}' .+ '\end{document}' /, "Contains a LaTeX document";

# TODO: add a test running the create-latex output through pdflatex.

done-testing;
