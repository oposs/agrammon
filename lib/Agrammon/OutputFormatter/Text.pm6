use v6;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::Outputs::FilterGroupCollection;
use Agrammon::OutputFormatter::Util;

sub output-as-text(
    Agrammon::Model $model,
    Agrammon::Outputs $outputs,
    Str $language,
    @print-set,
    Bool $include-filters,
    Bool :$all-filters = False --> Str
) is export {
    my @lines;
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        my @output-lines;
        my @title-lines;
        my $indent = '    ';
        push @title-lines, $module;
        when Hash {
            for sorted-kv($_) -> $output, $value {
                next unless $model.should-print($module, $output, @print-set);

                my $val = flat-value($value // 'UNDEFINED');
                my $unit = $model.output-unit($module, $output, $language);
                if $unit {
                    push @output-lines, "    $output = $val $unit";
                }
                else {
                    push @output-lines, "    $output = $val";
                }
                if $include-filters {
                    if $value ~~ Agrammon::Outputs::FilterGroupCollection && $value.has-filters {
                        add-filters(@output-lines, $value, $unit, $indent, :$all-filters);
                    }
                }
            }
            @lines.append: |@title-lines, |@output-lines if @output-lines;
        }
        when Array {
            my @subtitle-lines;
            @output-lines = [];
            for sorted-kv($_) -> $instance-id, %instance-outputs {
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    push @subtitle-lines, "    $q-name";
                    for sorted-kv(%values) -> $output, $value {
                        next unless $model.should-print($fq-name, $output, @print-set);

                        my $val = flat-value($value // 'UNDEFINED');
                        my $unit = $model.output-unit($module, $output, $language);
                        if $unit {
                            push @output-lines, "        $output = $val $unit";
                        }
                        else {
                            push @output-lines, "        $output = $val";
                        }
                        if $include-filters {
                            if $value ~~ Agrammon::Outputs::FilterGroupCollection && $value.has-filters {
                                add-filters(@output-lines, $value, $unit, $indent, :$all-filters);
                            }
                        }
                    }
                    NEXT {
                        @lines.append: |@title-lines, |@subtitle-lines, |@output-lines if @output-lines;
                        @title-lines =  @subtitle-lines = @output-lines = [];
                    }
                }
           }
        }
    }
    return @lines.join("\n");
}

sub add-filters(@module-lines, Agrammon::Outputs::FilterGroupCollection $collection,
        $unit, Str $prefix, Bool :$all-filters) {
    my @results = $collection.results-by-filter-group(:all($all-filters));
    my $longest-filter = @results.map({ .key.map({ .key.chars + .value.chars }) }).flat.max + 1;
    for @results {
        my %filters := .key;
        my $value := .value;
        my @filters = %filters.map: { .key ~ '=' ~ .value };
        for (@filters || '(Uncategorized)').kv -> $idx, $filter-id {
            my $padding = ' ' x $longest-filter - $filter-id.chars;
            push @module-lines, $idx == 0
                    ?? "$prefix  * $filter-id$padding    $value $unit"
                    !! "$prefix    $filter-id";
        }
    }
}
