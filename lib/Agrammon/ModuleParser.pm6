use v6;

grammar Agrammon::ModuleParser {
    token TOP {
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
        | <option=.multi-line-str-option>
        | <.blank-line>
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
        '+' <name=.ident> \h* \n
        [
        | <.blank-line>
        | '  ' <option=.single-line-option>
        | '  ' <option=.subsection-map>
        | '  +' <option=.multi-line-str-option(4)>
        ]*
    }

    token section-heading($title) {
        \h* '***' \h* $title \h* '***' \h* \n
    }

    token subsection-map {
        '++'<key=.ident> \h* \n
        [
        | '    ' <value=.single-line-option>
        | '    ++' <value=.multi-line-str-option(6)>
        ]+
    }

    token single-line-option {
        <key=.ident> \h* '=' \h* $<value>=[\N*] \n
    }

    token multi-line-str-option($*indent = 0) {
        '+' <key=.ident> \h* \n
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

    token blank-line {
        | \h* \n
        | \h* '#' \N* \n
    }
}
