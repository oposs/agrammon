use Agrammon::Model;
use Agrammon::Outputs;

sub output-for-gui(Agrammon::Model $model,
                   Agrammon::Outputs $outputs,
                   Bool $include-filters
                   ) is export {
    my %output = %(
        data => get-data($model, $outputs, $include-filters),
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

sub get-data($model, $outputs, $include-filters) {
    my @records;
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        when Hash {
            for sorted-kv($_) -> $output, $raw-value {
                my $var = $module ~ '::' ~ $output;
                push @records, make-record($module, $output, $model, $raw-value, $var);
                if $include-filters {
                    my $value = flat-value($raw-value);
                    if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                        push-filters(@records, $module, $output, $model, $raw-value, $var);
                    }
                }
            }
        }
        when Array {
            for sorted-kv($_) -> $instance-id, %instance-outputs {
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    for sorted-kv(%values) -> $output, $raw-value {
                        my $var = $q-name ~ '::' ~ $output;
                        push @records, make-record($fq-name, $output, $model, $raw-value, $var);
                        if $include-filters {
                            my $value = flat-value($raw-value);
                            if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                                push-filters(@records, $fq-name, $output, $model, $raw-value, $var);
                            }
                        }
                    }
                }
            }
        }
    }
    return @records;
}

sub make-record($fq-name, $output, $model, $raw-value, $var, $filter-id?) {
    my $format = $model.output-format($fq-name, $output);
    my $full-value = flat-value($raw-value);
    my $value = ($format  && $full-value.defined) ?? sprintf($format, $full-value)
                                                  !! $full-value;
    my $filter;
    if $filter-id {
        $filter-id ~~ / '=' (.+) /;
        $filter = ~$0;
    }
    return %(
        :$format,
        :print($model.output-print($fq-name, $output)),
        :order($model.output-order($fq-name, $output)),
        :labels($model.output-labels($fq-name, $output)),
        :units($model.output-units($fq-name, $output)),
        :fullValue($full-value),
        :$value,
        :$var,
        :$filter,
    );
}

sub push-filters(@records, $fq-name, $output, $model,
                 Agrammon::Outputs::FilterGroupCollection $collection,
                 $var) {
    my @results = $collection.results-by-filter-group;
    for @results {
        my %filters := .key;
        my $value := .value;
        my @filters = %filters.map: { .key ~ '=' ~ .value };
        for @filters.kv -> $idx, $filter-id {
            push @records, make-record($fq-name, $output, $model, $value, $var, $filter-id);
            # TODO: what does this do in text formatter? Do we need it here?
            #                    $idx == 0
            #                    ?? "$prefix $filter-id    $value $unit"
            #                    !! "$prefix $filter-id";
        }
    }
}


multi sub flat-value($value) {
    $value
}
multi sub flat-value(Agrammon::Outputs::FilterGroupCollection $collection) {
    +$collection
}

sub sorted-kv($_) {
    .sort(*.key).map({ |.kv })
}
