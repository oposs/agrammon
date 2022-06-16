use v6;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::Outputs::FilterGroupCollection;
use Agrammon::OutputFormatter::Util;

sub output-as-json(
    Agrammon::Model $model,
    Agrammon::Outputs $outputs,
    $language,
    @print-set,
    Bool $include-filters,
    Bool :$all-filters = False,
    Bool :$short = False
) is export {
    return get-data($model, $outputs, $include-filters, @print-set, $short, $language, :merge-filters);
}

sub output-for-gui(Agrammon::Model $model,
                   Agrammon::Outputs $outputs,
                   :$include-filters,
                   :$language
                   ) is export {
    my @print-set; # no filter
    return %(
        data => get-data($model, $outputs, $include-filters, @print-set, False, $language),
        log  => $outputs.log-collector.entries.map( *.to-json ),
    );
}

sub get-data($model, $outputs, $include-filters, @print-set, $short, $language?, :$merge-filters) {
    my @records;
    my $last-order = -1;
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        when Hash {
            for sorted-kv($_) -> $output, $raw-value {
                my $var = $module ~ '::' ~ $output;
                my $order = $model.output-labels($module, $output)<sort> || $last-order;
                my $record = make-record($module, $output, $model, $raw-value, $var, $order, $short, :$language, :@print-set);
                push @records, $record;
                if $include-filters {
                    if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                        if $merge-filters {
                            merge-filters($record, $module, $output, $model, $raw-value, $var, $order, $short, $language, :@print-set);
                        }
                        else {
                            add-filters(@records, $module, $output, $model, $raw-value, $var, $order, $short, :@print-set);
                        }
                    }
                }
                $last-order = $order;
            }
        }
        when Array {
            for sorted-kv($_) -> $instance-id, %instance-outputs {
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = module-with-instance($module, $instance-id, $fq-name);
                    for sorted-kv(%values) -> $output, $raw-value {
                        my $order = $model.output-labels($fq-name, $output)<sort> || $last-order;
                        my $var = $q-name ~ '::' ~ $output;
                        my $record =  make-record($fq-name, $output, $model, $raw-value, $var, $order, $short, $instance-id, :$language, :@print-set);
                        push @records, $record;
                        if $include-filters {
                            if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                                if $merge-filters {
                                    merge-filters($record, $fq-name, $output, $model, $raw-value, $var, $order, $short, $language, :@print-set);
                                }
                                else {
                                    add-filters(@records, $fq-name, $output, $model, $raw-value, $var, $order, $short, :@print-set);
                                }
                            }
                        }
                        $last-order = $order;
                    }
                }
            }
        }
    }
    return @records.sort(+*.<order>);
}

sub make-record($fq-name, $output, $model, $raw-value, $var, $order, $short, $instance-id?, :$language, :@filters, :@print-set) {
    next unless $model.should-print($fq-name, $output, @print-set);
    my $var-print = $model.output-print($fq-name, $output);
    my $format = $model.output-format($fq-name, $output);
    my $full-value = flat-value($raw-value);
    my $value = ($format && $full-value.defined)
            ?? sprintf($format, $full-value)
            !! $full-value;
    my %record = $short ?? %(
        :print($var-print),
        :value($full-value),
        :$var,
        :@filters,
    ) !! %(
        :$format,
        :print($var-print),
        :$order,
        :fullValue($full-value),
        :$value,
        :$var,
        :@filters,
    );

    # add instance name for multi module outputs
    %record<instance> = $instance-id if $instance-id;

    # add language specific strings if language specified
    if $language {
        %record<unit>  = $model.output-units($fq-name, $output){$language};
        %record<label> = $model.output-labels($fq-name, $output){$language};
    }
    # and language keyed hashes otherwise
    else {
        %record<units>  = $model.output-units($fq-name, $output);
        %record<labels> = $model.output-labels($fq-name, $output);
        %record<labels><sort>:delete if $short;
    }
    return %record;
}

sub add-filters(@records, $fq-name, $output, $model,
                Agrammon::Outputs::FilterGroupCollection $collection,
                $var, $order, $sort, :@print-set) {
    for $collection.results-by-filter-group {
        my %keyFilters := .key;
        my @filters = translate-filter-keys($model, %keyFilters).map: -> $trans { %( label => $trans.key, enum => $trans.value ) };
        my $value := .value;
        push @records, make-record($fq-name, $output, $model, $value, $var, $order, $sort, :@print-set, :@filters);
    }
}

sub merge-filters($record, $fq-name, $output, $model,
                Agrammon::Outputs::FilterGroupCollection $collection,
                $var, $order, $sort, $language?, :@print-set) {
    for $collection.results-by-filter-group {
        my %keyFilters := .key;
        my @filters = translate-filter-keys($model, %keyFilters).map: -> $trans { %( label => $trans.key, enum => $trans.value ) };
        my $value := .value;
#        TODO: make this an option
#        next unless $value;
        my $filter-record =  make-record($fq-name, $output, $model, $value, $var, $order, $sort, :@print-set, :@filters);
        push $record<values>, %( :label($filter-record<filters>[0]<enum>{$language}), :value($filter-record<fullValue>));
    }
    push $record<values>, %( :label($record<label>:delete), :value($record<fullValue>:delete));
    $record<order>:delete;
    $record<format>:delete;
    $record<value>:delete;
    $record<filters>:delete;
    return $record;
}
