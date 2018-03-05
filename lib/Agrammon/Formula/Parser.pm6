use Agrammon::Formula;
use Agrammon::Formula::Builder;

grammar Agrammon::Formula::Parser {
    rule TOP {
        <statementlist>
        [ $ || <.panic('Confused')> ]
    }

    rule statementlist {
        <statement>*
    }

    method panic($message) {
        die "$message near " ~ self.orig.substr(self.pos, 50).perl;
    }

    rule statement {
        | <statement_control> ';'?
        | <EXPR> [';' || <?before '}' | $>]
    }

    rule EXPR {
        <term> [ <infix> <term> ]*
    }

    proto token statement_control { * }

    rule statement_control:sym<if> {
        'if'
        [ '(' <EXPR> ')' || <.panic('Missing or malformed condition')> ]
        <then=.block>
        [ 'else' <else=.block> ]?
    }

    rule block {
        [ '{' || <.panic('Expected block')> ]
        <statementlist>
        [ '}' || <.panic('Missing } after block')> ]
    }

    proto token term { * }

    rule term:sym<In> {
        'In(' [<symbol=.ident> || <.panic('Bad identifier')>] ')'
    }
    rule term:sym<Tech> {
        'Tech(' [<symbol=.ident> || <.panic('Bad identifier')>] ')'
    }
    rule term:sym<Val> {
        'Val('
            [<symbol=.ident> || <.panic('Bad identifier')>]
            [',' || <.panic('Missing , in Val')>]
            [<module=.name> || <.panic('Missing or malformed module name')>]
        ')'
    }

    rule term:sym<my> {
        'my' <variable>
    }

    rule term:sym<variable> {
        <variable>
    }

    token variable {
        '$' <.ident>
    }

    token term:sym<integer> {
        \d+
    }

    proto token infix { * }
    token infix:sym<*> { '*' }
    token infix:sym<+> { '+' }
    token infix:sym<=> { '=' }
    token infix:sym<< > >> { '>' }

    token name {
        <.ident> ['::' <.ident>]*
    }
}

sub parse-formula(Str $formula) is export {
    Agrammon::Formula::Parser.parse($formula, actions => Agrammon::Formula::Builder).ast
}
