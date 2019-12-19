use v6;

class Agrammon::Model::Input {
    has Str $.name;
    has Str $.description;
    has     $.default-calc;
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
    #    has Str @.options;     # XXX set correct type: array of arrays
    #    has Str @.optionsLang; # XXX set correct type: array of hashes
    has @.options;     # XXX set correct type: array of arrays
    has @.options-lang; # XXX set correct type: array of hashes
    has  %.enum;
    has Int $.order;
    has Bool $!branch = False;
    has Bool $!filter = False;

    submethod TWEAK(:$default_calc, :$default_gui, :$branch, :$filter) {
        with $default_calc {
            $!default-calc = val($_);
        }
        with $default_gui {
            $!default-gui = val($_);
        }
        with $branch {
            if .lc eq 'true' {
                $!branch = True;
            }
        }
        with $filter {
            if .lc eq 'true' {
                $!filter = True;
            }
        }
    }

    method is-branch(--> Bool) { $!branch }

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
        my %enums = %!enum;

        for %enums.kv -> $name, $optLang {
            my $label   = $name;
            $label      ~~ s:g/_/ /;
            my @opt     = [ $label, '', $name];
            my @opt-lang = split("\n", $optLang);
            my %opt-lang;
            for @opt-lang -> $ol {
                my ($l, $o) = split(/ \s* '=' \s* /, $ol);
                $o ~~ s:g/_/ /;
                %opt-lang{$l} = $o;
            }
            push @options,     @opt;
            push @options-lang, %opt-lang;
        }

        return %(
            defaults    => %(
                calc => $.default-calc,
                gui  => $.default-gui,
            ),
            enum        => %!enum,
            help        => %!help,
            labels      => %!labels,
            models      => @!models || @("all"),
            options     => @options,
            optionsLang => @options-lang,
            order       => $!order // 500000,
            type        => $!type,
            units       => %units,
            variable    => $!name,
            validator   => %validator,
        )
    }

}
