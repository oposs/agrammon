use v6;
use Agrammon::DB;
use Agrammon::DB::Dataset;
use Agrammon::DB::User;

class Agrammon::DB::Datasets does Agrammon::DB {
    has Agrammon::DB::User $.user;
    has Agrammon::DB::Dataset @.collection;

    method load(Str $model-version) {
        self.with-db: -> $db {
            my $username = $!user.username;
            my $results = $db.query(q:to/DATASETS/, $username, $model-version);
                SELECT dataset_id AS id,
                       dataset_name AS name,
                       date_trunc('seconds', dataset_mod_date) AS "mod-date",
                       (SELECT COUNT(*)
                        FROM data_new WHERE data_dataset=dataset_id) AS records,
                       dataset_readonly AS "read-only",
                       dataset_version AS version,
                       '' AS tag,  -- tag attribute is set below
                                      dataset_comment AS comment,
                       dataset_model AS model,
                       dataset_pers != pers_email2id($1) AS "is-demo"
                  FROM dataset
                 WHERE dataset_version like '2%'
                   AND dataset_name not like '%_expanded'
                   AND (dataset_model IS NULL OR dataset_model=$2)
                   AND (dataset_pers=pers_email2id($1) OR dataset_pers=pers_email2id('default')
                                                       OR dataset_pers=pers_email2id('default2'))
                ORDER BY dataset_version DESC, "read-only" DESC,
                         dataset_mod_date DESC, dataset_name ASC
            DATASETS

            for $results.hashes -> $dh {
                my $ds = Agrammon::DB::Dataset.new(|$dh);
                @!collection.push($ds);
            }
        }
    }
    
    method list {
        return [@!collection.map: {.id, .name}];
    }
    
}
