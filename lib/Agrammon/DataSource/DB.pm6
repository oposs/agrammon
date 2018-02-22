use v6;
use DBIish;

class Agrammon::DataSource::DB {
    
    method read($dbh, $user, $dataset) {

        my $sth = $dbh.prepare(q:to/STATEMENT/);
            SELECT data_var, data_val, data_instance,
                   branches_data, branches_options,
                   data_comment
              FROM data_new LEFT JOIN branches ON (data_id=branches_var)
             WHERE data_dataset=dataset_name2id(?,?)
               AND data_var not like '%ignore'
          ORDER BY data_var, data_val
STATEMENT
                                 
         $sth.execute($user, $dataset);
         my @rows = $sth.allrows();
         return @rows;
    }

}
