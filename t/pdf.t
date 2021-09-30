use v6;

use Agrammon::Config;
use Agrammon::OutputFormatter::PDF;
use Test;
plan 6;

my %chemify-map = %(
    'NH3'     => '\\ce{NH3}',
    'N2O'     => '\\ce{N2O}',
    'NO2'     => '\\ce{NO2}',
    'N2'      => '\\ce{N2}',
    'N2,N2O'  => '\\ce{N2},\\ce{N2O}',
    'N2O,N2'  => '\\ce{N2O},\\ce{N2}',
    'NOx'     => '\\ce{NO_{(x)}}',
);

my %escape-map = %(
    '__' => '\hspace{2em}',
    '\\' => '\backslash',
    '_'  => '\_',
    '%'  => '\%',
    '}'  =>  '\}',
    '{'  => '\{',
    '$'  => '\$',
    '&'  => '\amp{}',
    '^'  => '\^{}',
    '~'  => '\~{}',
    '#'  => '\#',
    '|'  => '\|',
);

my %spaces-map = %(
    'kg / yr' => 'kg\\,/\\,yr',
);

subtest "latex prettify" => {
    subtest "latex-escape" => {
        for %escape-map.kv -> $plain, $expected {
            my $escaped = latex-escape($plain);
            is $escaped, $expected, "$plain -> $escaped";
        }
    }

    subtest "latex-chemify" => {
        for %chemify-map.kv -> $plain, $expected {
            my $escaped = latex-chemify($plain);
            is $escaped, $expected, "$plain -> $escaped";
        }
    }

    subtest "latex-spaces" => {
        for %spaces-map.kv -> $plain, $expected {
            my $escaped = latex-small-spaces($plain);
            is $escaped, $expected, "$plain -> $escaped";
        }
    }
}

my $cfg-file = %*ENV<AGRAMMON_CFG> // "t/test-data/agrammon.cfg.yaml";
my $username = 'fritz.zaucker@oetiker.ch';

my $cfg = Agrammon::Config.new;
ok $cfg.load($cfg-file), "Load config from file $cfg-file";

my %data = %(
    titles => %(
        :report('Report'),
        data => %(
            :section('Section'),
            :user('Username'),
            :dataset('Dataset'),
        ),
        :outputs('Results'),
        :inputs('Inputs'),
        :outputLog('Log'),
    ),
    :version('Agrammon 6.0'),
    :timestamp('Timestamp'),
    :dataset('TestDataset'), :username('fritz.zaucker@oetiker.ch'), :model('Single'),
    inputs => [
        %( :module('Module'), :first-module ),
        %( :value(42), :unit('Unit'), :label('Input'), :first-line ),
    ],
    outputs => [
        %( :section('Module'), :first ),
        %( :label('Weide NH3-Emission'), :value(5), :unit('kg\,N\,/\,Jahr') ),
        %( :label('Stall und Laufhof NH3-Emission'), :value(50), :unit('kg\,N\,/\,Jahr') ),
    ],
    log => [
        %( :gui('Module'), :instance(), :message('comment 1') ),
        %( :gui('Module'), :instance(), :message('comment 2') ),
    ],
);
my $pdf-program  = $cfg.general<pdflatex>;
my $dataset-name = 'TestDataset';
my $temp-dir   = $cfg.general<tempDir>;
my constant $source-dir = $*PROGRAM.parent.add('test-data');
my $pdf-file-expected   = "$source-dir/agrammon_export.pdf".IO;
my $latex-file-expected = "$source-dir/agrammon_export.tex".IO;

is create-latex('pdfexport', %data), $latex-file-expected.slurp, 'Create LaTeX document';

my $pdf-created;
lives-ok { $pdf-created = create-pdf($temp-dir, $pdf-program, $cfg.general<latexTimeout>, $username, $dataset-name, %data) }, "Create PDF";

if not %*ENV<GITHUB_ACTIONS> {
    is $pdf-created.bytes, $pdf-file-expected.s, "PDF file $pdf-file-expected size as expected";
}
else {
    skip "PDF size check not working on GitHub Actions for unknown reason", 1;
}

%data<log>.push(%( :gui('Module'), :instance(), :message('\invalidLatex')));
throws-like {create-pdf($temp-dir, $pdf-program, $cfg.general<latexTimeout>, $username, $dataset-name ~ '_broken', %data)},
        X::Agrammon::OutputFormatter::PDF::Failed, "Create PDF from invalid LaTeX file dies";

done-testing;
