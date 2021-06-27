use v6;

use JSON::Fast;

sub MAIN(Str $filename) {

    my %input-data = from-json($filename.IO.slurp)<inputs>;
    for %input-data.kv -> $full-tax, $module-data {
        note $full-tax;
        if $full-tax.index('[') -> $sub-start {
            my $tax = $full-tax.substr(0, $sub-start);
            my $sub-end = $full-tax.index(']');
            my $sub-tax = $full-tax.substr($sub-end + 1);
            $sub-tax = $sub-tax ?? $sub-tax.substr(2) !! '';
            for $module-data.kv -> $instance, $instance-inputs {
                note "    $instance";
                for $instance-inputs.kv -> $var, $value {
                    note "        $var = $value";
                    # $inputs.add-multi-input(
                    #     $tax, $instance, $sub-tax,
                    #     .key, maybe-numify(.value)
                    # );
                }
            }
        }
        else {
            for $module-data.kv -> $var, $value {
                note "   $var = $value"; 
                # $inputs.add-single-input($full-tax, .key, maybe-numify(.value));
            }

        }
    }
     
}
