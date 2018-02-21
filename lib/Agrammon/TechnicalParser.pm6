use v6;
no precompilation;
use Grammar::Tracer;

grammar Agrammon::TechnicalParser {
    token TOP {
        <.blank-line>*
        <section>+
    }

    proto token section { * }

    token name {
        <.ident> [ '::' <.ident> ]*
    }
    
    token section:sym<technical_parameters> {
        <.section-heading('technical_parameters')>
        [
        | <technical_parameters=.option-section>
        | <.blank-line>
        ]*
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
