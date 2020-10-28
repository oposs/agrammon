use v6;
use Agrammon::CommonParser;
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
