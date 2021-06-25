use v6;
use IO::Path::ChildSecure;

use Agrammon::CommonParser;
use Agrammon::Performance;
use Agrammon::TechnicalBuilder;

grammar Agrammon::TechnicalParser does Agrammon::CommonParser {
    token TOP {
        :my $*CUR-SECTION = '';
        <.blank-line>*
        <.section-heading('technical_parameters')>
        [
        | <parameters=.option-section>
        | <.blank-line>
        ]*
        [
        || $
        || <.panic('Confused')>
        ]
    }
}

sub parse-technical(Str $to-parse) is export {
    with Agrammon::TechnicalParser.parse($to-parse, actions => Agrammon::TechnicalBuilder) {
        return .ast;
    }
    else {
        die "Failed to parse technical configuration: unknown error";
    }
}

sub load-technical(IO::Path $model-path, Str $technical-file) is export {
    my $tech-input;
    # handle absolut path
    if $technical-file and $technical-file ~~ / ^ '/' / {
        $tech-input = $technical-file;
    }
    else {
        $tech-input = $model-path.IO.&child-secure($technical-file // 'technical.cfg');
    }
    timed "Load parameters from $tech-input", {
        my $params = parse-technical( $tech-input.IO.slurp );
        %($params.technical.map(-> %module {
            %module.keys[0] => %(%module.values[0].map({ .name => .value }))
        }));
    }
}
