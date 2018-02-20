use v6;

class Agrammon::Model::Output {
    has Str $.name;
    has Str $.description;
    has Str $.print;        # XXX Check what type this should really be
    has Str %.units{Str};
    has Str $.formula;      # XXX Should be something richer than Str
}
