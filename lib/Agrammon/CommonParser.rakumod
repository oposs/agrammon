use v6;
role Agrammon::CommonParser {
    method panic($message) {
        die "$message near " ~ self.orig.substr(self.pos, 50).raku;
    }

    token section-heading($title) {
        \h* '***' \h* $title \h* '***' \h* \n
        { $*CUR-SECTION = $title }
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

    token single-line-option {
        \h* <key> \h* '=' \h*
        $<value>=[[<!before \h*'#'>\N]*]
        \h* ['#'\N*]?
        [\n || $]
    }

    token subsection-map {
        \h* '++' \h* <key> \h* \n
        [
        | <value=.single-line-option>
        | <value=.multi-line-str-option('+++')>
        ]+
    }

    token multi-line-str-option($prefix) {
        \h* $prefix \h* <key> \h* \n
        # We want no leading lines and no trailing empty lines, but do want
        # interior empty lines. We eat lines up until we see a "terminator",
        # which is whitespace followed by *** (section heading) or + (next
        # option).
        <.blank-line>*
        $<value>=[
            [
                <!before \s* ['+' || '***' || $]>
                \N* [\n || $]
            ]*
        ]
        <.blank-line>*
    }

    token name {
        '::'? <.name-part> [ '::' <.name-part> ]*
    }

    token name-part {
        <.ident> | '..'
    }

    token key {
        <[\w+]>+
    }

    token blank-line {
        | \h* \n
        | \h* '#' \N* \n
        | \h+ $
    }
}
