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

    # Parse a stored branched var name `Taxonomy[]::SubTax::var` (or
    # `Taxonomy[]::var` with no sub-taxonomy) into (taxonomy, sub-taxonomy, var).
    sub parse-branch-var(Str $module-var) {
        $module-var ~~ m/(.+)'[]'(.+)/ or die "Malformed branched var: $module-var";
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
        return ($tax, $sub-tax, $var);
    }

    # TODO: remove ignore condition after DB cleanup
    method read($user, Str $dataset, %variant) {
        self.with-db: -> $db {
            my $results = $db.query(q:to/STATEMENT/, $user, $dataset, %variant<version>, %variant<gui>, %variant<model>);
                SELECT data_var, data_val, i.data_instance_name, data_comment
                FROM data
                LEFT JOIN data_instance i ON (data.data_instance_id = i.data_instance_id)
                WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5)
                    AND data_var not like '%ignore'
                ORDER BY i.data_instance_name, data_var, data_val
            STATEMENT
            my @rows = $results.arrays;
            my $dist-input = Agrammon::Inputs::Distribution.new(
                simulation-name => 'DB',
                dataset-id      => $dataset
            );

            my @flattend-to-add;

            for @rows -> @row {
                my $module-var = @row[0];
                my $value      = maybe-numify(@row[1]);
                my $instance   = @row[2] // '';
                my $comment    = @row[3];
                state $flattend-prefix = '';
                state Flattened $current-flattened;

                # branched data rows carry no value of their own; their matrix is
                # rebuilt from the dedicated branches query below.
                next if $value && $value eq 'branched';

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

                        if $value and $value eq 'flattened' {
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
                        else {
                            $dist-input.add-multi-input($tax, $instance, $sub-tax, $var, $value, :$comment);
                            $flattend-prefix = '';
                        }
                    }
                    else {
                        die "Malformed data: module-var=$module-var";
                    }
                }
                else {
                    $module-var ~~ m/(.+)'::'(.+)/;
                    my $tax     = "$0";
                    my $var     = "$1";
                    $dist-input.add-single-input($tax, $var, $value, :$comment);
                }
            }

            for @flattend-to-add {
                $dist-input.add-multi-input-flattened(.taxonomy, .instance-id, .sub-taxonomy,
                        .input-name, .value-percentages);
            }

            # Branched inputs: one self-describing row each, joined to both data
            # rows to recover variable names + instance. No ordering reliance.
            my @branches = $db.query(q:to/STATEMENT/, $user, $dataset, %variant<version>, %variant<gui>, %variant<model>).arrays;
                SELECT rv.data_var, cv.data_var, ri.data_instance_name,
                       b.branches_row_options, b.branches_col_options, b.branches_matrix
                FROM branches b
                JOIN data rv ON (b.branches_row_var = rv.data_id)
                JOIN data cv ON (b.branches_col_var = cv.data_id)
                LEFT JOIN data_instance ri ON (rv.data_instance_id = ri.data_instance_id)
                WHERE rv.data_dataset = dataset_name2id($1,$2,$3,$4,$5)
            STATEMENT

            for @branches -> @b {
                my ($row-tax, $row-sub, $row-var) = parse-branch-var(@b[0]);
                my ($col-tax, $col-sub, $col-var) = parse-branch-var(@b[1]);
                $dist-input.add-multi-input-branched(
                    $row-tax, @b[2],
                    $row-sub, $row-var, @b[3].list,
                    $col-sub, $col-var, @b[4].list,
                    @b[5]);
            }

            return $dist-input;
        }
    }
}
