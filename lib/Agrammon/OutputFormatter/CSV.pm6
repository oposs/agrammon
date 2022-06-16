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
        my $filters = $include-filters ?? 'total' !! '';
        when Hash {
            for sorted-kv($_) -> $output, $value {
                next unless $model.should-print($module, $output, @print-set);

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
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = module-with-instance($module, $instance-id, $fq-name);
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
        my %filters   := .key;
        my $raw-value := .value;
        my @filters = %filters.map: { %(:filter(.key), :value(.value)) };
        warn "CSV formatter must be extended for multiple filter groups" if @filters.elems > 1;
        for (@filters || ( :value('Uncategorized') ) ) {
            my @data = (
                |($prefix if $prefix),
                $q-name,  # module
                $fq-name, # variable
                .<value>,
                flat-value($raw-value) // '',
                $unit
            );
            take @data.join(';');
        }
    }
}
