use v6;

class Agrammon::Model::Input {
    has Str $.name;
    has Str $.description;
    has     $.default-calc;
    has     $.default-gui;
    has Str $.type;         # XXX Should be something richer than Str
    has Str $.validator;    # XXX Should be something richer than Str
    #    has Str %.labels{Str};
    has  %.labels;	
    #    has Str %.units{Str};
        has  %.units;
    #    has Str %.help{Str};
    has %.help;
    has Str @.models;
    #    has Str @.options;     # XXX set correct type: array of arrays
    has @.options;     # XXX set correct type: array of arrays
    #    has Str @.optionsLang; # XXX set correct type: array of hashes
    has @.optionsLang; # XXX set correct type: array of hashes
    has Int $.order;

    submethod TWEAK(:$default_calc) {
        with $default_calc {
            $!default-calc = val($_);
        }
    }

    method as-hash {
        my $validator = $.validator;
        my %validator;
        if $validator {
            $validator = $validator ~ '';
            $validator ~~ /(.+)\((.+)\)/;
            my $name = $0 ~ '';
            my $args = $1;
#            say "name=$name, args=", ($args // 'NONE');
            my @args = split(',', $args);
            %validator = %( name => $name, args => @args);
        }
        my %units = %!units;
        %units<de> = %!units<en> unless  %units<de>;
        %units<fr> = %!units<en> unless  %units<fr>;
        return %(
            defaults    => %(
                calc => $.default-calc,
                gui  => $.default-gui,
            ),
            help        => %!help,
            labels      => %!labels,
            models      => @!models || @("all"),
            options     => @!options,
            optionsLang => @!optionsLang,
            order       => $!order // 500000,
            type        => $!type,
            units       => %units,
            variable    => $!name,
            validator   => %validator,
        )
    }
}
