use v6;
use Agrammon::Model::External;
use Agrammon::Model::Input;
use Agrammon::Model::Result;
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
    has Agrammon::Model::Result @.results;
    has Str $.name;
    has Str $.parent;
    has %.gui-defaults;   # for display in GUI
    has %.technical-hash;
    has $.instance-root;
    has Agrammon::Model::Module $.gui-root-module;
    has Int $.load-order;

    submethod TWEAK {
        my $tax = $!taxonomy;
        if $tax ~~ /^(.+) '::' (.+)$/ {
            $!parent = ~$0;
            $!name   = ~$1;
        }
        else {
            $!parent = '';
            $!name   = ~$tax;
        }
        %!gui-defaults   = @!input.grep(*.default-gui.defined).map({ .name => .default-gui });
        %!technical-hash = @!technical.map({ .name => .value });
    }

    method is-multi() {
        $!instances // '' eq 'multi'
    }

    method set-instance-root(Str $!instance-root) {}

    method set-gui-root(Agrammon::Model::Module $!gui-root-module) {}

    #| Returns a copy of $input-hash with enum-typed input values canonicalized:
    #| values that are declared `accepts =` aliases (e.g. cross-version
    #| migration) are rewritten to the local enum key so that formulas only
    #| ever see the canonical local values. Non-enum values pass through.
    method canonicalize-input-hash(%input-hash --> Hash) {
        my %out = %input-hash;
        for @!input -> Agrammon::Model::Input $input {
            next unless $input.type eq 'enum';
            my $name = $input.name;
            with %out{$name} -> $value {
                if $input.is-mapped-enum-value($value) {
                    %out{$name} = $input.canonical-enum-value($value);
                }
            }
        }
        %out
    }
}
