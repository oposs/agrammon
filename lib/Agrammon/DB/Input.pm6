use v6;
use Agrammon::DB;
use Agrammon::DB::User;

class Agrammon::DB::Input does Agrammon::DB {
    has Str $.var;
    has     $.value;
    has Str $.dataset;
    has Agrammon::DB::User $.user;

    method store($instance_test) {
        self.with-db: -> $db {
            my $ret = $db.query(q:to/INPUT/, $!value, $!user.username, $!dataset, $!var);
            UPDATE data_new SET data_val = $1
             WHERE data_dataset=dataset_name2id($2,$3) AND data_var=$4
                                                       AND $instance_test
            INPUT
            
#            my $results = $db.query(q:to/DATASET/, $!name);
#                INSERT INTO tag (tag_name)
#                VALUES ($1)
#                RETURNING tag_id
#            DATASET

            $!id = $results.value;
        }
        return self;
    }

}
