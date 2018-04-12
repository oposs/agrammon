use v6;
use Agrammon::CommonParser;

grammar Agrammon::ModuleParser does Agrammon::CommonParser {
    token TOP {
        :my $*TAXONOMY = '';
        <.blank-line>*
        <section>+
        [
        || $
        || <.panic('Confused')>
        ]
    }

    proto token section { * }

    token section:sym<general> {
        <.section-heading('general')>
        [
        | <option=.single-line-option>
        | <option=.multi-line-str-option('+')>
        | <.blank-line>
        ]*
    }

    token section:sym<external> {
        <.section-heading('external')>
        [
        | <.blank-line>
        | <external=.option-section>
        ]*
    }

    token section:sym<input> {
        <.section-heading('input')>
        [
        | <.blank-line>
        | <input=.option-section>
        ]*
    }

    token section:sym<technical> {
        <.section-heading('technical')>
        [
        | <.blank-line>
        | <technical=.option-section>
        ]*
    }

    token section:sym<output> {
        <.section-heading('output')>
        [
        | <.blank-line>
        | <output=.option-section>
        ]*
    }

    token section:sym<results> {
        <.section-heading('results')>
        [
        | <.blank-line>
        | <results=.option-section>
        ]*
    }

    token section:sym<tests> {
        <.section-heading('tests')>
        [
        | <.blank-line>
        | <tests=.option-section>
        ]*
    }
}
