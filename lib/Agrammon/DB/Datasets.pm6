use v6;
use Agrammon::Config;
use Agrammon::DB::Dataset;
use Agrammon::DB::User;
use DB::Pg;

class Agrammon::DB::Datasets {
    has Agrammon::DB::User $.user;
    has Agrammon::DB::Dataset @.collection;

    method load(Str $model-version, Agrammon::Config $cfg) {
        my $username = $!user.username;
        my $pg = DB::Pg.new(conninfo => $cfg.db-conninfo);
        my $data = $pg.query(q:to/DATASETS/, $username, $model-version);
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

        for $data.hashes -> $dh {
            my $ds = Agrammon::DB::Dataset.new(|$dh);
            @!collection.push($ds);
        }
    }

    
}
