use v6;

use Agrammon::Formula;
use Agrammon::Formula::Compiler;
use Agrammon::LanguageParser;

class Agrammon::Model::Input {
    has Str $.name;
    has Str $.description;
    has     $.default-calc;
    has Agrammon::Formula $.default-formula;
    has     &.compiled-default-formula;
    has     $.default-gui;
    has Str $.type;         # XXX Should be something richer than Str
    has Str $.validator;    # XXX Should be something richer than Str
    ### TODO: those are multi-level hashes; not sure how to do the typing right
    #    has Str %.labels{Str};
    #    has Str %.units{Str};
    #    has Str %.help{Str};
    has %.labels;
    has %.units;
    has %.help;
    has Str @.models;
    has @!enum-order;
    has %!enum-lookup;
    has Int $.order;
    has Bool $!distribute = False;
    has Bool $!filter = False;

    submethod TWEAK(:$default_calc, :$default_gui, :$default_formula, :$default_formula_code,
                    :$distribute, :$filter, :@enum --> Nil) {
        with $default_calc {
            $!default-calc = val($_);
        }
        with $default_formula {
            $!default-formula = $default_formula;
            &!compiled-default-formula = compile-formula($default_formula);
        }
        with $default_gui {
            $!default-gui = val($_);
        }
        with $distribute {
            $!distribute = .lc eq 'true';
        }
        if @enum {
            @!enum-order = @enum.map({ .key => parse-lang-values(.value, "input $!name") });
            %!enum-lookup = @!enum-order;
        }
        with $filter {
            $!filter = .lc eq 'true';
        }
    }

    method enum(--> Hash) { %!enum-lookup }

    method enum-ordered(--> Array) { @!enum-order }

    method is-valid-enum-value($value) { %!enum-lookup{$value}:exists }

    method is-distribute(--> Bool) { $!distribute }

    method is-filter(--> Bool) { $!filter }

    method as-hash {
        my $validator = $.validator;
        my %validator;
        if $validator {
            $validator ~~ /(.+)\((.+)\)/;
            my $name = ~$0;
            my $args = $1;
            my @args = split(',', $args);
            %validator = :$name, :@args;
        }
        my %units = %!units;
        %units<de> ||= %!units<en>;
        %units<fr> ||= %!units<en>;

        my @options;
        my @options-lang;

        for @!enum-order {
            my $name = .key;
            my $label = $name.subst('_', ' ', :g);
            push @options, [$label, '', $name];
            push @options-lang, .value;
        }

        return %(
            :defaults( %(
                calc => $.default-calc,
                gui  => $.default-gui,
            )),
            :enum(%!enum-lookup),
            :$!filter,
            :%!help,
            :%!labels,
            :models(@!models || @("all")),
            :@options,
            :optionsLang(@options-lang),
            :order($!order // 500000),
            :$!type,
            :%units,
            :variable($!name),
            :%validator,
        );
    }

}
