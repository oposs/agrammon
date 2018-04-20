use v6;

class Agrammon::Model::Result {
    has Str $.name;
    has Str $.type;
    has  %.selector{Str};
    has %.data;
    has Str $._order;

}
