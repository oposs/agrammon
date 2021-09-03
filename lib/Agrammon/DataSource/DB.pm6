use v6;
use Agrammon::DB;
use Agrammon::Inputs;
use Agrammon::DataSource::Util;

class Agrammon::DataSource::DB does Agrammon::DB {
    my class Flattened {
        has Str $.taxonomy;
        has Str $.instance-id;
        has Str $.sub-taxonomy;
        has Str $.input-name;
        has %.value-percentages;
    }

    my class Branched {
        has Str $.taxonomy;
        has Str $.instance-id;
        has Str $.sub-taxonomy-a;
        has Str $.input-name-a;
        has Str @.input-values-a;
        has Str $.sub-taxonomy-b is rw;
        has Str $.input-name-b is rw;
        has Str @.input-values-b is rw;
        has @.matrix is rw;
    }

    # TODO: remove ignore condition after DB cleanup
    method read($user, Str $dataset, %variant) {
        self.with-db: -> $db {
            my $results = $db.query(q:to/STATEMENT/, $user, $dataset, %variant<version>, %variant<gui>, %variant<model>);
                SELECT data_var, data_val, data_instance,
                       branches_data, branches_options,
                       data_comment
                FROM data_new LEFT JOIN branches ON (data_id=branches_var)
                WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5)
                    AND data_var not like '%ignore'
                ORDER BY data_instance, branches_var, data_var, data_val
            STATEMENT
            my @rows = $results.arrays;
            my $dist-input = Agrammon::Inputs::Distribution.new(
                simulation-name => 'DB',
                dataset-id      => $dataset
            );

            my @flattend-to-add;
            my @branched-to-add;

            for @rows -> @row {
                my $module-var = @row[0];
                my $value      = maybe-numify(@row[1]) // '';
                my $instance   = @row[2] // '';
                state $flattend-prefix = '';
                state Flattened $current-flattened;
                state Branched $current-branched;

                if $instance {
                    if $module-var ~~ m/(.+)'[]'(.+)/ {
                        my $tax     = "$0";
                        my $sub-var = "$1";
                        my ($sub-tax, $var);
                        if $sub-var ~~ m/'::'(.+)'::'(.+)/ {
                            $sub-tax = "$0";
                            $var     = "$1";
                        }
                        else {
                            $sub-tax = '';
                            $sub-var ~~ s/'::'//;
                            $var = $sub-var;
                        }

                        if $current-branched && $value ne 'branched' {
                            die "Missing second step of branched input";
                        }

                        if $value eq 'flattened' {
                            $flattend-prefix = $var;
                            $current-flattened = Flattened.new:
                                    taxonomy => $tax,
                                    instance-id => $instance,
                                    sub-taxonomy => $sub-tax,
                                    input-name => $var;
                            push @flattend-to-add, $current-flattened;
                        }
                        elsif $flattend-prefix && $var.starts-with($flattend-prefix ~ '_flattened') {
                            my $key = $var.substr(($flattend-prefix ~ '_flattened00_').chars);
                            # TODO: flattened variables should be stored with _ instead of space
                            $key ~~ s:g/ ' ' /_/;
                            $current-flattened.value-percentages{$key} = $value;
                        }
                        elsif $value eq 'branched' {
                            with $current-branched {
                                .sub-taxonomy-b = $sub-tax;
                                .input-name-b = $var;
                                .input-values-b = @row[4].list;
                                .matrix = @row[3].rotor(@row[4].elems);
                                push @branched-to-add, $_;
                                $_ = Nil;
                            }
                            else {
                                $current-branched = Branched.new:
                                        taxonomy => $tax,
                                        instance-id => $instance,
                                        sub-taxonomy-a => $sub-tax,
                                        input-name-a => $var,
                                        input-values-a => @row[4].list;
                            }
                        }
                        else {
                            $dist-input.add-multi-input($tax, $instance, $sub-tax, $var, $value);
                            $flattend-prefix = '';
                        }
                    }
                    else {
                        die "Malformed data: module-var=$module-var";
                    }
                }
                else {
                    die "Missing second step of branched input" if $current-branched;
                    $module-var ~~ m/(.+)'::'(.+)/;
                    my $tax     = "$0";
                    my $var     = "$1";
                    $dist-input.add-single-input($tax, $var, $value);
                }
            }

            for @flattend-to-add {
                $dist-input.add-multi-input-flattened(.taxonomy, .instance-id, .sub-taxonomy,
                        .input-name, .value-percentages);
            }
            for @branched-to-add {
                $dist-input.add-multi-input-branched(.taxonomy, .instance-id,
                         .sub-taxonomy-a, .input-name-a, .input-values-a,
                         .sub-taxonomy-b, .input-name-b, .input-values-b,
                         .matrix);
            }
            return $dist-input;
        }
    }
}
