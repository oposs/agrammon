use Agrammon::Model;
use Agrammon::Outputs;

sub output-as-json(Agrammon::Model $model,
                   Agrammon::Outputs $outputs,
                   $language, $prints,
                   Bool $include-filters
                   ) is export {
    return get-data($model, $outputs, $include-filters, $language, $prints);
}

sub output-for-gui(Agrammon::Model $model,
                   Agrammon::Outputs $outputs,
                   :$include-filters,
                   :$language
                   ) is export {
    my %output = %(
        data => get-data($model, $outputs, $include-filters, $language),
        log  => %(),
    );
    return %output;
}

sub get-data($model, $outputs, $include-filters, $language?, $prints?) {
    my @records;
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        when Hash {
            for sorted-kv($_) -> $output, $raw-value {
                my $var = $module ~ '::' ~ $output;
                push @records, make-record($module, $output, $model, $raw-value, $var, :$language, :$prints);
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
                        push @records, make-record($fq-name, $output, $model, $raw-value, $var, :$language, :$prints);
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

sub make-record($fq-name, $output, $model, $raw-value, $var, :$language, :$prints, :%filters) {
    my $format = $model.output-format($fq-name, $output);
    my $full-value = flat-value($raw-value);
    my $value = ($format  && $full-value.defined) ?? sprintf($format, $full-value)
                                                  !! $full-value;

    # skip if prints filter is set and doesn't match this record
    my $print = $model.output-print($fq-name, $output);
    next if $prints and not $print ~~ $prints;

    my %record = %(
        :$format,
        :$print,
        :order($model.output-order($fq-name, $output)),
        :fullValue($full-value),
        :$value,
        :$var,
        :%filters,
    );

    # add language specific strings if language specified
    if $language {
        %record<unit>  = $model.output-units($fq-name, $output){$language};
        %record<label> = $model.output-labels($fq-name, $output){$language};
    }
    # and language keyed hashes otherwise
    else {
        %record<units>  = $model.output-units($fq-name, $output);
        %record<labels> = $model.output-labels($fq-name, $output);
    }
    return %record;
}

sub push-filters(@records, $fq-name, $output, $model,
                 Agrammon::Outputs::FilterGroupCollection $collection,
                 $var) {
    # model filter groups
    my %fgs = $model.filter-groups;

    # add existing filter groups
    for $collection.results-by-filter-group {
        my %filters := .key;
        my $value   := .value;
        push @records, make-record($fq-name, $output, $model, $value, $var, :%filters);
        for %filters.kv -> $key, $value {
            # remove from model filter group
            %fgs{$key}{$value}:delete;
        }
    }

    # add remaining model filter groups
    for %fgs.kv -> $fg, %values {
        for %values.kv -> $key, $value {
            push @records, make-record($fq-name, $output, $model, Nil, $var, :filters( %( $fg => $key) ) );
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
