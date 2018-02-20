use v6;
use Agrammon::Model::Input;
use Agrammon::Model::Output;
use Agrammon::Model::Technical;

class Agrammon::Model::Module {
    has Str $.author;
    has Str $.date;
    has Str $.taxonomy;
    has Str $.short;
    has Str $.description;
    has Agrammon::Model::Input @.input;
    has Agrammon::Model::Technical @.technical;
    has Agrammon::Model::Output @.output;
}
