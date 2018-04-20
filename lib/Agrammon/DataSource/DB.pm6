use v6;
use Agrammon::DB;
use Agrammon::Inputs;

class Agrammon::DataSource::DB does Agrammon::DB {
    
    method read($user, Str $dataset) {
        self.with-db: -> $db {

            my $results = $db.query(q:to/STATEMENT/, $user, $dataset);
                SELECT data_var, data_val, data_instance,
                       branches_data, branches_options,
                       data_comment
                  FROM data_new LEFT JOIN branches ON (data_id=branches_var)
                 WHERE data_dataset=dataset_name2id($1,$2)
                   AND data_var not like '%ignore'
              ORDER BY data_var, data_val
            STATEMENT
                                 
            my @rows = $results.arrays;

            my $input = Agrammon::Inputs.new(
                simulation-name => 'DB',
                dataset-id      => $dataset
            );

            for @rows {
                my $module-var = .[0];
                my $value      = maybe-numify(.[1]) // '';
                my $instance   = .[2] // '';

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
                    }
                    else {
                        die "Mal-formed data: module-var=$module-var";
                    }
                    $input.add-multi-input($tax, $instance, $sub-tax, $var, $value);
                }
                else {
                    $module-var ~~ m/(.+)'::'(.+)/;
                    my $tax     = "$0";
                    my $var     = "$1";
                    $input.add-single-input($tax, $var, $value);
                }
            }
            return $input;
        }
    }

    sub maybe-numify($value) {
        +$value // $value
    }
}
