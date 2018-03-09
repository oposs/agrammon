use v6;
use Agrammon::DB;

class Agrammon::DataSource::DB does Agrammon::DB {
    
    method read($user, $dataset) {
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
             return @rows;
        }
    }

}
