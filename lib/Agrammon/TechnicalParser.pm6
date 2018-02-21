use v6;

grammar Agrammon::TechnicalParser {
    token TOP {
        <.blank-line>*
        <.section-heading('technical_parameters')>
        [
        | <parameters=.option-section>
        | <.blank-line>
        ]*
    }

    token name {
        <.ident> [ '::' <.ident> ]*
    }

    token option-section {
        '+' <name> \h* \n
        [
        | <.blank-line>
        | '  ' <option=.single-line-option>
        ]*
    }

    token section-heading($title) {
        \h* '***' \h* $title \h* '***' \h* \n
    }

    token single-line-option {
        <key=.ident> \h* '=' \h* $<value>=[\N*] \n
    }

    token blank-line {
        | \h* \n
        | \h* '#' \N* \n
    }
}
