use v6;
use Agrammon::DB::Dataset;
use Agrammon::DB::User;
use Agrammon::DB::Variant;
use Agrammon::Timestamp;

class Agrammon::DB::Datasets does Agrammon::DB::Variant {
    has Agrammon::DB::User    $.user;
    has Agrammon::DB::Dataset @.collection;

    method load {
        self.with-db: -> $db {
            my $username = $!user.username;
            # Filter datasets to the active Model.version and anything in
            # Model.compatibleVersions; compat rows are promoted to the
            # active version on first open by Dataset!ensure-version-match.
            my @versions = (%!agrammon-variant<version>, |self!compatible-versions);
            my (Str $gui, Str $model) = %!agrammon-variant<gui model>;
            my $results = $db.query(q:to/DATASETS/, ~$username, @versions, $gui, $model);
                SELECT dataset_id AS id,
                       dataset_name AS name,
                       date_trunc('seconds', dataset_mod_date) AS "mod-date",
                       (SELECT COUNT(*)
                        FROM data_new WHERE data_dataset=dataset_id) AS records,
                       dataset_readonly AS "read-only",
                       dataset_version AS version,
                       dataset_guivariant AS "guivariant",
                       dataset_modelvariant AS "modelvariant",
                       '' AS tag,  -- tag attribute is set below
                       dataset_comment AS comment,
                       dataset_model   AS model,
                       dataset_pers != pers_email2id($1) AS "is-demo"
                  FROM dataset
                 WHERE dataset_version  = ANY($2)
                   AND (dataset_model  = 'UNKNOWN' OR dataset_guivariant= $3 AND dataset_modelvariant = $4)
                   AND dataset_name    NOT LIKE '%_expanded'
                   AND (dataset_pers=pers_email2id($1) OR dataset_pers=pers_email2id('default')
                                                       OR dataset_pers=pers_email2id('default2'))
                ORDER BY "read-only" DESC,
                         dataset_mod_date DESC,
                         dataset_name ASC
            DATASETS

            for $results.hashes -> %dh {
                my %agrammon-variant := {
                    version => %dh<version>:delete,
                    gui     => %dh<guivariant>:delete,
                    model   => %dh<modelvariant>:delete,
                };
                my $ds = Agrammon::DB::Dataset.new(:%agrammon-variant, |%dh);
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

    method delete(@datasets) {
        my $deleted = 0;
        my $user = $!user.id;
        # Scope the delete to the active variant exactly like `load` above:
        # dataset names are only unique per (name, pers, version, modelvariant,
        # guivariant), so deleting by (pers, name) alone wipes same-named
        # datasets in *other* variants/versions that the GUI never showed.
        my @versions = (%!agrammon-variant<version>, |self!compatible-versions);
        my (Str $gui, Str $model) = %!agrammon-variant<gui model>;
        for @datasets -> $ds {
            self.with-db: -> $db {
                my $results = $db.query(q:to/DATASET/, $user, $ds, @versions, $gui, $model);
                    DELETE FROM dataset
                     WHERE dataset_pers      = $1
                       AND dataset_name      = $2
                       AND dataset_version   = ANY($3)
                       AND (dataset_model = 'UNKNOWN'
                            OR dataset_guivariant = $4 AND dataset_modelvariant = $5)
                    RETURNING dataset_id
                DATASET
                $deleted += $results.rows;
            }
        }
        return $deleted;
    }

    method send(@datasets, $new-username) {

        for @datasets -> $old-dataset {
            my $new-dataset = "$old-dataset - Kopie von " ~ $!user.username ~  " - " ~ timestamp;
            Agrammon::DB::Dataset.new(
                :$!user, :%!agrammon-variant
            ).clone(:$new-username, :$old-dataset, :$new-dataset);
        }
        # expected by GUI
        return %( :sent(@datasets.elems) );
    }

    method list {
        return [@!collection.map: {.name, .mod-date, .records, .read-only, .agrammon-variant<version>, .tags.map(*.name), .comment, .model, .is-demo}];
    }

}
