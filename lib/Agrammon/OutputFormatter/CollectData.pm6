use v6;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::Outputs::FilterGroupCollection;

sub collect-data(
    Agrammon::Model $model,
    Agrammon::Outputs $outputs, Agrammon::Inputs $inputs, $reports,
    Str $language, $prints,
    Bool $include-filters, Bool $all-filters
) is export {

    # add inputs
    my @inputs;
    for $model.annotate-inputs($inputs) -> $ai {
        my $gui = $ai.gui-root{$language} // 'NO GUI ROOT';
        my $value = $ai.value;
        my $value-translated = $value;
        if $value and $ai.input.enum {
            $value-translated = $ai.input.enum{$value}{$language} // $value;
        }
        @inputs.push( %(
            :module($ai.module.taxonomy),
            :instance($ai.instance-id // ''),
            :input($ai.input.labels{$language} // $ai.input.labels<en> // $ai.input.name),
            :$value,
            :$value-translated,
            :unit($ai.input.units{$language} // $ai.input.units<en> // ''),
            :$gui,
        ));
    }

    my @prints = $reports[+$prints]<data> if defined $prints;
    my %print-labels;
    my @print-set;
    for @prints -> @print {
        for @print -> $print {
            @print-set.push($print<print>);
            %print-labels{$print<print>} = $print<langLabels>;
        }
    }

    # add outputs
    my @outputs = ();
    my $last-order = -1;
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        when Hash {
            for sorted-kv($_) -> $output, $raw-value {
                my $value = flat-value($raw-value // 'UNDEFINED');
                my $var-print = $model.output-print($module, $output) ~ ',All';
                if not defined $prints or $var-print.split(',') ∩ @print-set {
                    my $print = ($var-print.split(',') ∩ @print-set).keys[0];
                    my $order = $model.output-labels($module, $output)<sort> || $last-order;
                    my $unit  = $model.output-unit($module, $output, $language);
                    my $output-label = $language ?? $model.output-labels($module, $output){$language} !! $output;
                    my $unit-label   = $language ?? $model.output-units($module, $output){$language}  !! $unit;
                    @outputs.push(%( :module(''), :label($output-label), :$value, :unit($unit-label), :$order, :$print));
                    if $include-filters {
                        if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                            push-filters(
                                @outputs, $module, $model, $raw-value, $unit, $language, $order,
                                :$all-filters
                            );
                        }
                    }
                    $last-order = $order;
                }
            }
        }
        when Array {
            for sorted-kv($_) -> $instance-id, %instance-outputs {
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    for sorted-kv(%values) -> $output, $raw-value {
                        my $value = flat-value($raw-value // 'UNDEFINED');
                        my $var-print = $model.output-print($module, $output) ~ ',All';
                        if not $prints or $var-print.split(',') ∩ @print-set {
                            my $print = ($var-print.split(',') ∩ @print-set).keys[0];
                            my $order = $model.output-labels($module, $output)<sort> || $last-order;
                            my $unit  = $model.output-unit($module, $output, $language);
                            my $output-label = $language ?? $model.output-labels($module, $output){$language} !! $output;
                            my $unit-label   = $language ?? $model.output-units($module, $output){$language}  !! $unit;
                            @outputs.push(%( :module(''), :label($output-label), :$value, :unit($unit-label), :$order, :$print));
                            if $include-filters {
                                if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value
                                .has-filters {
                                    push-filters(
                                        @outputs, $q-name, $model, $raw-value, $unit-label, $language, $order,
                                       :$all-filters
                                    );
                                }
                            }
                            $last-order = $order;
                        }
                    }
                }
            }
        }
    }

    return %( :@inputs, :@outputs, :%print-labels );
}

sub push-filters(@records, $module, $model, Agrammon::Outputs::FilterGroupCollection $collection,
                   $unit, $language, $order, Bool :$all-filters) {
    my @results = $collection.results-by-filter-group(:all($all-filters));
    for @results {
        my %keyFilters := .key;
        my %filters    := translate-filter-keys($model, %keyFilters);
        my $value      := .value;
#        we might need the %label for multiple filter groups later
#        for %filters.kv -> %label, %enum {
        for %filters.values -> %enum {
            my $label = %enum{$language};
            @records.push( %( :$module, :label('....' ~ $label), :$value, :$unit, :$order) );
        }
    }
}

sub sorted-kv($_) {
    .sort(*.key).map({ |.kv })
}

multi sub flat-value($value) {
    $value
}

multi sub flat-value(Agrammon::Outputs::FilterGroupCollection $collection) {
    +$collection
}
