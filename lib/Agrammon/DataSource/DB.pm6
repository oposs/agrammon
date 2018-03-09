use v6;

class Agrammon::DataSource::DB {
    
    method read($db, $user, $dataset) {

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
            dd @rows;
         return @rows;
    }

}
