use v6;
use Agrammon::Model::External;
use Agrammon::Model::Input;
use Agrammon::Model::Test;
use Agrammon::Model::Output;
use Agrammon::Model::Technical;

class Agrammon::Model::Module {
    has Str $.author;
    has Str $.date;
    has Str $.taxonomy;
    has Str $.instances;
    has Str $.gui;
    has Str $.short;
    has Str $.description;
    has Agrammon::Model::External @.external;
    has Agrammon::Model::Input @.input;
    has Agrammon::Model::Technical @.technical;
    has Agrammon::Model::Output @.output;
    has Agrammon::Model::Test @.tests;
    has Str $.name;
    has Str $.parent;
    has %.input-defaults;
    has %.technical-hash;
    has $.instance-root;

    method TWEAK {
        my $tax = $!taxonomy;
        if $tax ~~ /^(.+) '::' (.+)$/ {
            $!parent = "$0";
            $!name   = "$1";
        }
        else {
            $!parent = '';
            $!name   = "$tax";
        }
        %!input-defaults = @!input.grep(*.default-calc.defined).map({ .name => .default-calc });
        %!technical-hash = @!technical.map({ .name => .value });
    }

    method is-multi() {
        $!instances // '' eq 'multi'
    }

    method set-root(Str $root) {
        $!instance-root = $root;
    }

}


