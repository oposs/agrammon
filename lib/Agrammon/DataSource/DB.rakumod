use v6;
use Agrammon::DB;
use Agrammon::Inputs;
use Agrammon::DataSource::Util;

class Agrammon::DataSource::DB does Agrammon::DB {
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

            for @rows -> @row {
                my $module-var = @row[0];
                my $value      = maybe-numify(@row[1]);
                my $instance   = @row[2] // '';
                my $comment    = @row[3];

                # branched/flattened marker rows carry no value of their own;
                # their distribution is rebuilt from the dedicated queries below.
                next if $value && ($value eq 'branched' || $value eq 'flattened');

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

                        $dist-input.add-multi-input($tax, $instance, $sub-tax, $var, $value, :$comment);
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

            # Flattened inputs: one self-describing row each, joined to the marker
            # data row to recover variable name + instance. Options/fractions zip
            # directly into the percentage map (no state machine / substr / munge).
            my @flattened = $db.query(q:to/STATEMENT/, $user, $dataset, %variant<version>, %variant<gui>, %variant<model>).arrays;
                SELECT fv.data_var, fi.data_instance_name,
                       f.flattened_options, f.flattened_fractions
                FROM flattened f
                JOIN data fv ON (f.flattened_var = fv.data_id)
                LEFT JOIN data_instance fi ON (fv.data_instance_id = fi.data_instance_id)
                WHERE fv.data_dataset = dataset_name2id($1,$2,$3,$4,$5)
            STATEMENT

            for @flattened -> @f {
                my ($tax, $sub, $var) = parse-branch-var(@f[0]);
                my %value-percentages = @f[2].list Z=> @f[3].list>>.Numeric;
                $dist-input.add-multi-input-flattened($tax, @f[1], $sub, $var, %value-percentages);
            }

            return $dist-input;
        }
    }
}
