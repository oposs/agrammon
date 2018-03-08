use v6;
use Agrammon::Dataset;
use Agrammon::User;
use DB::Pg;

class Agrammon::Datasets {
    has Agrammon::User $.user;
    has Agrammon::Dataset @.collection;

    method load(Str $model-version) {
        my $username = $!user.username;
        my $pg = DB::Pg.new(conninfo => 'dbname=agrammon_dev host=erika.oetiker.ch user=agrammon password=agrammon@work');
        my @data = $pg.query(q:to/DATASETS/, $username, $model-version).arrays;
            SELECT dataset_id,
                   dataset_name,
                   date_trunc('seconds', dataset_mod_date),
                   (SELECT COUNT(*)
                    FROM data_new WHERE data_dataset=dataset_id) AS num,
                   dataset_readonly AS readOnly,
                   dataset_version,
                   '',  -- tag attribute is set below
                   dataset_comment, dataset_model,
                   dataset_pers != pers_email2id($1) AS demo
              FROM dataset
             WHERE dataset_version like '2%'
               AND dataset_name not like '%_expanded'
               AND (dataset_model IS NULL OR dataset_model=$2)
               AND (dataset_pers=pers_email2id($1) OR dataset_pers=pers_email2id('default')
                                                   OR dataset_pers=pers_email2id('default2'))
            ORDER BY dataset_version DESC, readOnly DESC,
                     dataset_mod_date DESC, dataset_name ASC
        DATASETS

        for @data -> @d {
            my $ds = Agrammon::Dataset.new(
                id        => @d[0],
                name      => @d[1],
                read-only => @d[4],
                model     => @d[8],
                comment   => @d[7],
                version   => @d[5],
                mod-date  => @d[2],
                user      => $!user
            );
            @!collection.push($ds);
        }
    }

    
}
