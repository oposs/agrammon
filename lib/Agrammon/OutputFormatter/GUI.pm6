use Agrammon::Model;
use Agrammon::Outputs;

sub output-for-gui(Agrammon::Model $model,
                   Agrammon::Outputs $outputs) is export {
    my %output = %(
        data => get-data($model, $outputs),
        log  => %(),
        pid  => 333,
### TODO: is this still needed with the new implementation?
#        raw  => _get_raw($model, $outputs)
    );
    return %output;
}

### TODO: see above
#sub _get_raw($model, $outputs) {
#    return ();
#}

sub get-data($model, $outputs) {
    my @records;
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        when Hash {
            for sorted-kv($_) -> $output, $value {
                my $format = $model.output-format($module, $output);
                my $formattedValue = $format ?? sprintf($format, $value)
                                             !! $value;
                push @records, %(
                    format    => $format,
                    print     => $model.output-print($module, $output),
                    order     => $model.output-order($module, $output),
                    labels    => $model.output-labels($module, $output),
                    units     => $model.output-units($module, $output),
                    fullValue => $value,
                    value     => $formattedValue,
                    var       =>  $module ~ '::' ~ $output,
                );
            }
        }
        when Array {
            for sorted-kv($_) -> $instance-id, %instance-outputs {
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    for sorted-kv(%values) -> $output, $value {
                        my $format = $model.output-format($fq-name, $output);
                        my $formattedValue = $format ?? sprintf($format, $value)
                                                     !! $value;
                        push @records, %(
                            format    => $format,
                            print     => $model.output-print($fq-name, $output),
                            order     => $model.output-order($fq-name, $output),
                            labels    => $model.output-labels($fq-name, $output),
                            units     => $model.output-units($fq-name, $output),
                            fullValue => $value,
                            value     => $formattedValue,
                            var       =>  $q-name ~ '::' ~ $output,
                        );

                    }
                }
            }
        }
    }
    return @records;
}

sub sorted-kv($_) {
    .sort(*.key).map({ |.kv })
}
