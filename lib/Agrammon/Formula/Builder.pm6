use Agrammon::Formula;
use Agrammon::OutputReference;

class Agrammon::Formula::Builder {
    method TOP($/) {
        make $<EXPR>.ast;
    }

    method EXPR($/) {
        make $<term>.ast;
    }

    method term:sym<In>($/) {
        make Agrammon::Formula::In.new(symbol => ~$<symbol>);
    }

    method term:sym<Tech>($/) {
        make Agrammon::Formula::Tech.new(symbol => ~$<symbol>);
    }

    method term:sym<Val>($/) {
        make Agrammon::Formula::Val.new(
            reference => Agrammon::OutputReference.new(
                symbol => ~$<symbol>,
                module => ~$<module>
            )
        );
    }
}
