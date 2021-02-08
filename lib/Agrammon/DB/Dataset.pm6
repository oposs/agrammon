use v6;
use Agrammon::DB;
use Agrammon::DB::Tag;
use Agrammon::DB::User;

#| Error when a dataset already exists for the user.
class X::Agrammon::DB::Dataset::AlreadyExists is Exception {
    has Str $.dataset-name is required;
    method message {
        "Dataset '$!dataset-name' already exists."
    }
}

#| Error when dataset couldn't be cloned.
class X::Agrammon::DB::Dataset::CloneFailed is Exception {
    has Str $.old-dataset is required;
    has Str $.new-dataset is required;
    has Str $.old-username is required;
    has Str $.new-username is required;
    method message {
        "Dataset '$!old-dataset' of '$!old-username' couldn't be copied to '$!new-dataset' of '$!new-username'."
    }
}

#| Error when dataset couldn't be renamed.
class X::Agrammon::DB::Dataset::RenameFailed is Exception {
    has Str $.dataset-name is required;
    has Str $.old-name is required;
    has Str $.new-name is required;
    method message {
        "Dataset '$!dataset-name' couldn't be renamed from '$!old-name' to '$!new-name'."
    }
}

#| Error when dataset couldn't be reordered.
class X::Agrammon::DB::Dataset::InstanceReorderFailed is Exception {
    has Str $.dataset-name is required;
    method message {
        "Dataset 'Instances of $!dataset-name' couldn't be reordered'."
    }
}

#| Error when an instance already exists for the user.
class X::Agrammon::DB::Dataset::InstanceAlreadyExists is Exception {
    has Str $.name is required;
    method message {
        "Instance '$!name' already exists."
    }
}

#| Error when instance couldn't be deleted.
class X::Agrammon::DB::Dataset::InstanceDeleteFailed is Exception {
    has Str $.instance is required;
    method message {
        "Instance '$!instance' couldn't be deleted."
    }
}

#| Error when instance couldn't be renamed.
class X::Agrammon::DB::Dataset::InstanceRenameFailed is Exception {
    has Str $.old-name is required;
    has Str $.new-name is required;
    method message {
        "Dataset '$!old-name' couldn't be renamed to '$!new-name'."
    }
}

#| Error when input comment couldn't be renamed.
class X::Agrammon::DB::Dataset::StoreInputCommentFailed is Exception {
    has Str $.comment is required;
    has Str $.variable is required;
    method message {
        "Couldn't save comment '$!comment' for variable '$!variable'."
    }
}

#| Error when dataset comment couldn't be renamed.
class X::Agrammon::DB::Dataset::StoreDatasetCommentFailed is Exception {
    has Str $.comment is required;
    has Str $.dataset is required;
    method message {
        "Couldn't save comment '$!comment' for dataset '$!dataset'."
    }
}

#| Error when data couldn't be saved.
class X::Agrammon::DB::Dataset::StoreDataFailed is Exception {
    has Str $.variable is required;
    method message {
        "Data for variable '$!variable' couldn't be saved."
    }
}

#| Error when tag couldn't be set.
class X::Agrammon::DB::Dataset::SetTagFailed is Exception {
    has Str $.tag-name is required;
    method message {
        "Tag '$!tag-name' couldn't be set."
    }
}

#| Error when tag couldn't be removed.
class X::Agrammon::DB::Dataset::RemoveTagFailed is Exception {
    has Str $.tag-name is required;
    method message {
        "Tag '$!tag-name' couldn't be removed."
    }
}

class Agrammon::DB::Dataset does Agrammon::DB {
    has Int  $.id;
    has Str  $.name;
    has Bool $.read-only;
    has Str  $.model;
    has Str  $.comment;
    has Str  $.version is default('2.0-stage'); # TODO: get from config
    has Int  $.records; # TODO: is this needed?
    has DateTime $.mod-date;
    has $.data;
    has Agrammon::DB::Tag  @.tags;
    has Agrammon::DB::User $.user;

    method !create-dataset( $dataset-name, $username, $version, $model ) {
        my @ret;
        self.with-db: -> $db {
            @ret = $db.query(q:to/SQL/, $dataset-name, $version, $model, $username).array;
                INSERT INTO dataset (dataset_name, dataset_pers,
                                     dataset_version, dataset_model)
                  SELECT $1, pers_id, $2, $3
                    FROM pers
                   WHERE pers_email = $4
                RETURNING dataset_id, dataset_mod_date
            SQL
            CATCH {
                # new dataset name already exists
                when /unique/ {
                    die X::Agrammon::DB::Dataset::AlreadyExists.new(:$dataset-name);
                }
            }
        }
        return { :id(@ret[0]), :mod-date(@ret[1]) };
    }

    method create {
        my $ds = self!create-dataset( $!name, $!user.username, $!version, $!model );
        $!id = $ds<id>;
        $!mod-date = $ds<mod-date>;
        return self;
    }

    method clone(:$new-username, :$old-dataset, :$new-dataset) {
        my $old-username = $!user.username;

        # old and new dataset are identical
        die X::Agrammon::DB::Dataset::AlreadyExists.new(:dataset-name($new-dataset))
            if $old-dataset eq $new-dataset and $old-username eq $new-username;

        my $ds = self!create-dataset( $new-dataset, $new-username, $!version, $!model);
        self.with-db: -> $db {
            $db.query(q:to/SQL/, $ds<id>, $old-username, $old-dataset);
                INSERT INTO data_new (data_dataset, data_var, data_instance, data_val, data_instance_order, data_comment)
                     SELECT $1, data_var, data_instance, data_val, data_instance_order, data_comment
                       FROM data_new
                      WHERE data_dataset = dataset_name2id($2, $3)
            SQL

            CATCH {
                die X::Agrammon::DB::Dataset::CloneFailed.new(:$old-username, :$new-username, :$old-dataset, :$new-dataset);
            }
        }
    }

    method rename(Str $new) {
        self.with-db: -> $db {
            # old and new name are identical
            die X::Agrammon::DB::Dataset::RenameFailed.new(:dataset-name($new), :old-name($!name), :new-name($new)) if $new eq $!name;

            my $ret = $db.query(q:to/SQL/, $new, $!name, $!user.id);
                UPDATE dataset SET dataset_name = $1
                 WHERE dataset_name = $2 AND dataset_pers = $3
                RETURNING dataset_name
            SQL
            # new dataset name already exists
            CATCH {
                when /unique/ {
                    die X::Agrammon::DB::Dataset::AlreadyExists.new(:dataset-name($new));
                }
            }

            # update failed
            die X::Agrammon::DB::Dataset::RenameFailed.new(:dataset-name($new), :old-name($!name), :new-name($new)) unless $ret.rows;

            # rename suceeded
            $!name = $new;
        }
    }

    method submit($email) {
        my $new-dataset = 'newDataset';

        # TODO: clone dataset; implement sending eMail
        warn "Submitting dataset and sending mail for submit($email) not yet implemented";
        return $new-dataset;
    }

    method lookup {
        self.with-db: -> $db {
            my $username = $!user.username;
            my $results = $db.query(q:to/DATASET/, $!user.id, $!name);
            SELECT dataset_id
              FROM dataset LEFT JOIN pers ON dataset_pers=pers_id
             WHERE dataset_pers = $1
               AND dataset_name = $2
            DATASET
            $!id = $results.value;
        }
        return self;
    }


    #| Set tag on datasets.
    method set-tag(@datasets, $tag-name --> Nil) {
        self.with-db: -> $db {
            my $tag-id = Agrammon::DB::Tag.new( :name($tag-name), :$!user).lookup.id;
            die X::Agrammon::DB::Tag::UnknownTag($tag-name) unless $tag-id;

            for @datasets -> $dataset-name {
                my $ds-id = Agrammon::DB::Dataset.new(:$!user, :name($dataset-name)).lookup.id;
                $db.query(q:to/SQL/, $tag-id, $ds-id);
                    INSERT INTO tagds (tagds_tag, tagds_dataset)
                         VALUES       ($1, $2)
                    ON CONFLICT ON CONSTRAINT tagds_tagds_dataset_key
                    DO NOTHING
                SQL
                CATCH {
                    # other DB failure
                    die X::Agrammon::DB::Dataset::SetTagFailed.new(:$tag-name);
                }
            }
        }
    }

    #| Remove tag from datasets.
    method remove-tag(@datasets, $tag-name --> Nil) {
        self.with-db: -> $db {
            my $tag-id = Agrammon::DB::Tag.new( :name($tag-name), :$!user).lookup.id;
            die X::Agrammon::DB::Tag::UnknownTag($tag-name) unless $tag-id;

            for @datasets -> $dataset-name {
                $db.query(q:to/SQL/, $tag-id, $dataset-name);
                    DELETE FROM tagds
                     WHERE tagds_tag IN ( SELECT tag_id
                                            FROM tag
                                           WHERE tag_name = $1 )
                       AND tagds_dataset IN ( SELECT dataset_id
                                                FROM dataset
                                                WHERE dataset_name = $2 )
                SQL
                CATCH {
                    # other DB failure
                    die X::Agrammon::DB::Dataset::RemoveTagFailed.new(:$tag-name);
                }
            }
        }
    }

    method load {
        self.with-db: -> $db {
            my $username = $!user.username;
            my $results = $db.query(q:to/DATASET/, $username, $!name);
            SELECT data_var, data_val, data_instance_order, branches_data, data_comment
              FROM data_view LEFT JOIN branches ON (branches_var=data_id)
             WHERE data_dataset=dataset_name2id($1,$2)
               AND data_var not like '%::ignore'
             ORDER BY data_instance_order ASC, data_var
            DATASET
            $!data = $results.arrays;
        }
        return self;
    }

    method load-branch-data {
        warn "*** load-branch-data() not yet implemented";
        my @data;
        # self.with-db: -> $db {
        #     my $username = $!user.username;
        #     my $results = $db.query(q:to/DATASET/, $username, $!name);
        #     SELECT data_var, data_val, data_instance_order, branches_data, data_comment
        #       FROM data_view LEFT JOIN branches ON (branches_var=data_id)
        #      WHERE data_dataset=dataset_name2id($1,$2)
        #        AND data_var not like '%::ignore'
        #      ORDER BY data_instance_order ASC, data_var
        #     DATASET
        #     $!data = $results.arrays;
        # }
        return @data;
    }

    method store-branch-data(%data) {
        warn "*** store-branch-data() not yet implemented";
        my @data;
        # self.with-db: -> $db {
        #     my $username = $!user.username;
        #     my $results = $db.query(q:to/DATASET/, $username, $!name);
        #     SELECT data_var, data_val, data_instance_order, branches_data, data_comment
        #       FROM data_view LEFT JOIN branches ON (branches_var=data_id)
        #      WHERE data_dataset=dataset_name2id($1,$2)
        #        AND data_var not like '%::ignore'
        #      ORDER BY data_instance_order ASC, data_var
        #     DATASET
        #     $!data = $results.arrays;
        # }
        return @data.keys.elems;
    }

    method store-comment($comment) {

        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $comment, $username, $!name);
            UPDATE dataset SET dataset_comment = $1
             WHERE dataset_id=dataset_name2id($2,$3)
            RETURNING dataset_comment
            SQL
            $!comment = $comment;

            # couldn't save comment
            die X::Agrammon::DB::Dataset::StoreDatasetCommentFailed.new(:$comment, :dataset($!name)) unless $ret.rows;

            return $ret.rows;
        }
    }

    method !store-variable-comment($variable, $comment) {
        my $username = $!user.username;
        self.with-db: -> $db {
                my $ret = $db.query(q:to/SQL/, $comment, $username, $!name, $variable);
                UPDATE data_new SET data_comment = $1
                 WHERE data_dataset=dataset_name2id($2,$3) AND data_var = $4
                                                           AND data_instance IS NULL
                RETURNING data_comment
            SQL
            return $ret.rows if $ret.rows;

            $ret = $db.query(q:to/SQL/, $comment, $username, $!name, $variable);
                INSERT INTO data_new (data_dataset, data_var, data_comment)
                     VALUES          (dataset_name2id($2,$3), $4, $1)
                RETURNING data_comment
                SQL

            # couldn't save comment
            die X::Agrammon::DB::Dataset::StoreInputCommentFailed.new(:$comment, :$variable) unless $ret.rows;

            return $ret.rows;
        }
    }

    method !store-instance-variable-comment($variable, $instance, $comment) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $comment, $username, $!name, $variable, $instance);
                UPDATE data_new SET data_comment = $1
                 WHERE data_dataset=dataset_name2id($2,$3) AND data_var = $4
                                                           AND data_instance = $5
                RETURNING data_comment
            SQL

            return $ret.rows if $ret.rows;

            $ret = $db.query(q:to/SQL/, $comment, $username, $!name, $variable, $instance);
                INSERT INTO data_new (data_dataset, data_var, data_comment, data_instance)
                     VALUES          (dataset_name2id($2,$3), $4, $1, $5)
                RETURNING data_comment
            SQL

            # couldn't save comment
            die X::Agrammon::DB::Dataset::StoreInputCommentFailed.new(:$comment, :$variable) unless $ret.rows;

            return $ret.rows;
        }
    }

    method store-input-comment($variable, $comment) {
        my $instance;
        my $variable-name = $variable;
        if $variable-name ~~ s/\[(.+)\]/[]/ {
            $instance = $0;
        }

        $instance ?? self!store-instance-variable-comment($variable, $instance, $comment)
                  !! self!store-variable-comment($variable, $comment);
    }

    method !store-variable($variable, $value) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $value, $username, $!name, $variable);
                UPDATE data_new SET data_val = $1
                 WHERE data_dataset=dataset_name2id($2,$3) AND data_var = $4
                                                           AND data_instance IS NULL
                RETURNING data_val
            SQL
            return $ret.rows if $ret.rows;

            $ret = $db.query(q:to/SQL/, $value, $username, $!name, $variable);
                INSERT INTO data_new (data_dataset, data_var, data_val)
                     VALUES          (dataset_name2id($2,$3), $4, $1)
                RETURNING data_val
            SQL

            # couldn't store variable
            die X::Agrammon::DB::Dataset::StoreDataFailed.new($variable) unless $ret.rows;

            return $ret.rows;
        }
    }

    method !store-instance-variable($variable, $instance, $value) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $value, $username, $!name, $variable, $instance);
                UPDATE data_new SET data_val = $1
                 WHERE data_dataset=dataset_name2id($2,$3) AND data_var = $4
                                                           AND data_instance = $5
                RETURNING data_comment
            SQL

            return $ret.rows if $ret.rows;

            $ret = $db.query(q:to/SQL/, $value, $username, $!name, $variable, $instance);
                INSERT INTO data_new (data_dataset, data_var, data_val, data_instance)
                     VALUES (dataset_name2id($2,$3), $4, $1, $5)
                RETURNING data_comment
            SQL

            # couldn't store variable
            die X::Agrammon::DB::Dataset::StoreDataFailed.new($variable) unless $ret.rows;

            return $ret.rows;
        }
    }

    method store-input($var-name, $value) {
        my $instance;

        my $var = $var-name;
        if $var ~~ s/\[(.+)\]/[]/ {
            $instance = $0;
        }

        $instance ?? self!store-instance-variable($var, $instance, $value)
                  !! self!store-variable($var, $value);
    }

    method !delete-variable($var) {

        return unless $var;
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $username, $!name, $var);
            DELETE FROM data_new
             WHERE data_dataset=dataset_name2id($1,$2) AND data_var=$3
                                                       AND data_instance IS NULL
            RETURNING data_val
            SQL

            return $ret.rows;
        }
    }

    method delete-instance($variable-pattern, $instance --> Nil) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $username, $!name, $variable-pattern ~ '%', $instance);
                DELETE FROM data_new
                 WHERE data_dataset=dataset_name2id($1,$2) AND data_var LIKE $3
                                                           AND data_instance = $4
                RETURNING data_val
            SQL

            # update failed
            die X::Agrammon::DB::Dataset::InstanceDeleteFailed.new(:$instance) unless $ret.rows;
        }
    }

    method rename-instance($old-name, $new-name, $pattern --> Nil) {
        my $username = $!user.username;

        self.with-db: -> $db {
            # old and new name are identical
            die X::Agrammon::DB::Dataset::InstanceRenameFailed.new(:$old-name, :$new-name) if $old-name eq $new-name;

            my $ret = $db.query(q:to/SQL/, $new-name, $username, $!name, "$pattern\%", $old-name);
                UPDATE data_new set data_instance = $1
                 WHERE data_dataset = dataset_name2id($2,$3)
                   AND data_var LIKE $4
                   AND data_instance = $5
                RETURNING data_val
            SQL

            # new instance name already exists
            CATCH {
                when /unique/ {
                    die X::Agrammon::DB::Dataset::InstanceAlreadyExists.new(:$old-name, :$new-name);
                }
            }

            # update failed
            die X::Agrammon::DB::Dataset::InstanceRenameFailed.new(:$old-name, :$new-name) unless $ret.rows;
        }
    }

    method order-instances(@instances) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $i = 0;
            for @instances.kv -> $i, $pattern {
                $pattern     ~~ / (.+) '[' (.+) ']' /;
                my $var      = $0;
                my $instance = $1;
                $var         = "$var\[\]%";
                $db.query(q:to/SQL/, $i, $username, $!name, $var, $instance);
                UPDATE data_new SET data_instance_order = $1
                 WHERE data_dataset = dataset_name2id($2,$3)
                   AND data_var     LIKE $4
                   AND data_instance = $5
                RETURNING data_instance_order
                SQL
            }
        }

        # reordering failed
        CATCH {
            die X::Agrammon::DB::Dataset::InstanceReorderFailed.new(:$!name);
        }
    }

}
