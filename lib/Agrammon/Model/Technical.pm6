use v6;

class Agrammon::Model::Technical {
    has Str $.name;
    has Str $.description;
    has Str %.units{Str};
    has $.value;
}
