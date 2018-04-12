use v6;
use Agrammon::DB;
use Agrammon::DB::Dataset;
use Agrammon::DB::User;

class Agrammon::DB::Datasets does Agrammon::DB {
    has Str $.version;
    has Agrammon::DB::User    $.user;
    has Agrammon::DB::Dataset @.collection;

    method load {
        self.with-db: -> $db {
            my $username = $!user.username;
            my $results = $db.query(q:to/DATASETS/, $username, $!version);
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

            for $results.hashes -> %dh {
                my $ds = Agrammon::DB::Dataset.new(|%dh);
                @!collection.push($ds);
            }

            my $tagResults = $db.query(q:to/TAGS/, $username);
                   SELECT dataset_name AS dataset, tag_name AS tag
                     FROM tag JOIN tagds   ON (tagds_tag=tag_id)
                              JOIN dataset ON (tagds_dataset=dataset_id)
                    WHERE (dataset_pers=pers_email2id($1))
            TAGS
            my @tagHashes = [$tagResults.hashes];

            for @!collection -> $ds {
                my @tags;
                for @tagHashes -> %th {
                    if %th<dataset> eq $ds.name {
                        my $tag = Agrammon::DB::Tag.new(:name(%th<tag>));
                        @tags.push($tag) ;
                    }
                }
                $ds.tags = @tags;
            }
        }
        return self;
    }
    
    method list {
        return [@!collection.map: {.name, .mod-date, .records, .read-only, .version, .tags, .comment, .model, 0}];
    }
    
}
