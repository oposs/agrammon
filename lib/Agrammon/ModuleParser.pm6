use v6;

grammar Agrammon::ModuleParser {
    token TOP {
        :my $*TAXONOMY = '';
        <.blank-line>*
        <section>+
        [
        || $
        || <.panic('Confused')>
        ]
    }

    method panic($message) {
        die "$message near " ~ self.orig.substr(self.pos, 50).perl;
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

    token section:sym<tests> {
        <.section-heading('tests')>
        [
        | <.blank-line>
        | <tests=.option-section>
        ]*
    }

    token option-section {
        \h* '+' \h* <name> \h* \n
        [
        | <.blank-line>
        | <option=.single-line-option>
        | <option=.subsection-map>
        | <option=.multi-line-str-option('++')>
        ]*
    }

    token section-heading($title) {
        \h* '***' \h* $title \h* '***' \h* \n
    }

    token subsection-map {
        \h* '++' \h* <key=.ident> \h* \n
        [
        | <value=.single-line-option>
        | <value=.multi-line-str-option('+++')>
        ]+
    }

    token single-line-option {
        \h* <key=.ident> \h* '=' \h* $<value>=[\N*] \n
    }

    token multi-line-str-option($prefix) {
        \h* $prefix \h* <key=.ident> \h* \n
        # We want no leading lines and no trailing empty lines, but do want
        # interior empty lines. We eat lines up until we see a "terminator",
        # which is whitespace followed by *** (section heading) or + (next
        # option).
        <.blank-line>*
        $<value>=[
            [
                <!before \s* ['+' || '***']>
                \N* \n
            ]*
        ]
    }

    token name {
        <.name-part> [ '::' <.name-part> ]*
    }

    token name-part {
        <.ident> | '..'
    }

    token blank-line {
        | \h* \n
        | \h* '#' \N* \n
    }
}
