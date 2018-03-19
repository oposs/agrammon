use v6;
use Agrammon::CommonParser;
use Agrammon::TechnicalBuilder;

grammar Agrammon::TechnicalParser does Agrammon::CommonParser {
    token TOP {
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
