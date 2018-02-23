use Agrammon::Formula;
use Agrammon::Formula::Builder;

grammar Agrammon::Formula::Parser {
    rule TOP {
        || <EXPR> ';'? $
        || <.panic('Confused')>
    }

    method panic($message) {
        die "$message near " ~ self.orig.substr(self.pos, 50).perl;
    }

    rule EXPR {
        <term>
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

    token name {
        <.ident> ['::' <.ident>]*
    }
}

sub parse-formula(Str $formula) is export {
    Agrammon::Formula::Parser.parse($formula, actions => Agrammon::Formula::Builder).ast
}
