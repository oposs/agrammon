use v6;
use Agrammon::Formula;

class Agrammon::Model::Output {
    has Str $.name;
    has Str $.description;
    has Str $.print;        # XXX Check what type this should really be
    has Str %.units{Str};
    has Str %.labels{Str};
    has Str $.format;
    has Str $.order;
    has Agrammon::Formula $.formula;
    has &.compiled-formula is rw;
}
