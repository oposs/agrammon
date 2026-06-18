use v6;

use Agrammon::Formula;
use Agrammon::Formula::Compiler;
use Agrammon::LanguageParser;

class Agrammon::Model::Input {
    has Str $.name;
    has Str $.description;
    has     $.default-value;
    has Agrammon::Formula $.default-formula;
    has     &.compiled-default-formula is rw;
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
    has %!enum-aliases;
    has Int $.order;
    has Bool $!hidden = False;
    has Bool $!distribute = False;
    has Bool $!filter = False;

    submethod TWEAK(:$default_value, :$default_formula, :$default_formula_code,
                    :$hidden, :$distribute, :$filter, :@enum --> Nil) {
        with $default_value {
            $!default-value = val($_);
        }
        with $default_formula {
            $!default-formula = $default_formula;
        }
        with $hidden {
            $!hidden = .lc eq 'true';
        }
        with $distribute {
            $!distribute = .lc eq 'true';
        }
        if @enum {
            @!enum-order = @enum.map({
                my $key = .key;
                my %lang-values = parse-lang-values(.value, "input $!name");
                with %lang-values<accepts>:delete -> $accepts {
                    for @$accepts -> $alias {
                        if %!enum-aliases{$alias}:exists {
                            warn "Duplicate enum alias '$alias' in input $!name " ~
                                 "(already maps to '%!enum-aliases{$alias}', now also '$key')";
                        }
                        %!enum-aliases{$alias} = $key;
                    }
                }
                $key => %lang-values
            });
            %!enum-lookup = @!enum-order;
        }
        with $filter {
            $!filter = .lc eq 'true';
        }
    }

    method enum(--> Hash) {
        %!enum-lookup
    }

    method enum-ordered(--> Array) {
        @!enum-order
    }

    method is-valid-enum-value($value) {
        %!enum-lookup{$value}:exists or %!enum-aliases{$value}:exists
    }

    #| Returns the canonical (locally declared) enum key for $value.
    #| If $value is already a local key, returns it unchanged. If it is
    #| a declared alias, returns the local key it maps to. Otherwise Nil.
    method canonical-enum-value($value) {
        return $value if %!enum-lookup{$value}:exists;
        return %!enum-aliases{$value} // Nil;
    }

    #| True iff $value is a declared alias (i.e. comes from another model
    #| version) and is being mapped onto a local enum key.
    method is-mapped-enum-value($value --> Bool) {
        %!enum-aliases{$value}:exists
    }

    method enum-aliases(--> Hash) {
        %!enum-aliases
    }

    method is-distribute(--> Bool) {
        $!distribute
    }

    method is-filter(--> Bool) {
        $!filter
    }

    method is-hidden(--> Bool) {
        $!hidden
    }

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
            :defaults(%(
                value => $.default-value,
                hasFormula => $.default-formula.defined,
            )),
            # NB: the enum value set is sent as @options (keys + neutral labels)
            # + optionsLang (per-language labels); the old `enum` lookup hash
            # duplicated that and was unused by the GUI (#301). enumAliases stays
            # — it serves a different purpose (cross-version value mapping).
            :enumAliases(%!enum-aliases),
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

    method as-template-hash($language) {
        my %input =
            variable => $!name,
            unit => %!units{$language} // %!units<en> // '',
            label => %!labels{$language} // %!labels<en>;
        if $!type eq 'enum' {
            %input<enums> = %!enum-lookup;
        }
        %input<help> = %!help{$language} // %!help<en> // '';
        %input<validator> = $!validator if $!validator;
        with $.default-formula {
            %input<hasDefaultFormula> = $.default-formula.defined;
        }
        with $.default-value {
            %input<default> = $.default-value;
        }
        return %input
    }
}
