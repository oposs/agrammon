use v6;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::Outputs::FilterGroupCollection;
use Agrammon::OutputFormatter::Util;

sub output-as-csv(
    $simulation-name,
    $dataset-id,
    Agrammon::Model $model,
    Agrammon::Outputs $outputs,
    Str $language,
    @print-set,
    Bool $include-filters,
    Bool :$all-filters = False --> Str
) is export {
    return (gather for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        my $prefix = "$simulation-name;$dataset-id" if $simulation-name;
        when Hash {
            for sorted-kv($_) -> $output, $value {
                next unless $model.should-print($module, $output, @print-set);

                my $filters = '';
                my $raw-value = $value;
                my $var = $output;
                my $unit = $model.output-unit($module, $output, $language);
                my @data = (
                    |($prefix if $prefix),
                    $module,
                    $var,
                    $filters,
                    flat-value($raw-value) // '',
                    $unit
                );
                take @data.join(';');
                if $include-filters {
                    if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                        add-filters($raw-value, $module, $var, $unit, $prefix, :$all-filters);
                    }
                }
            }
        }
        when Array {
            for sorted-kv($_) -> $instance-id, %instance-outputs {
                my $filters = '';
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    for sorted-kv(%values) -> $output, $value {
                        next unless $model.should-print($module, $output, @print-set);

                        my $raw-value = $value;
                        my $unit = $model.output-unit($module, $output, $language);
                        my @data = (
                            |($prefix if $prefix),
                            $q-name,
                            $output,
                            $filters,
                            flat-value($raw-value) // '',
                            $unit
                        );
                        take @data.join(';');
                        if $include-filters {
                            if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                                add-filters($raw-value, $q-name, $fq-name, $unit, $prefix, :$all-filters);
                            }
                        }
                    }
                }
            }
        }
    }).join("\n");
}

sub add-filters(Agrammon::Outputs::FilterGroupCollection $collection,
        $q-name, $fq-name, $unit, Str $prefix, Bool :$all-filters) {
    my @results = $collection.results-by-filter-group(:all($all-filters));
    for @results {
        my %filters := .key;
        my $raw-value := .value;
        my $filters = %filters.values.join(',');
        my @filters = %filters.map: { .key ~ '=' ~ .value };
        for (@filters || '(Uncategorized)') {
            my @data = (
                |($prefix if $prefix),
                $q-name,
                $fq-name,
                $filters,
                flat-value($raw-value) // '',
                $unit
            );
            take @data.join(';');
        }
    }
}
