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

#| Error when dataset couldn't be renamed.
class X::Agrammon::DB::Dataset::RenameFailed is Exception {
    has Str $.dataset-name is required;
    has Str $.old-name is required;
    has Str $.new-name is required;
    method message {
        "Dataset '$!dataset-name' couldn't be renamed from '$!old-name' to '$!new-name'."
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

#| Error when instance couldn't be renamed.
class X::Agrammon::DB::Dataset::StoreInputCommentFailed is Exception {
    has Str $.comment is required;
    has Str $.variable is required;
    method message {
        "Couldn't save comment '$!comment' for variable '$!variable'."
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
    has Str $.name is required;
    method message {
        "Tag '$!name' couldn't be set."
    }
}

| Error when tag couldn't be removed.
class X::Agrammon::DB::Dataset::RemoveTagFailed is Exception {
    has Str $.name is required;
    method message {
        "Tag '$!name' couldn't be removed."
    }
}

class Agrammon::DB::Dataset does Agrammon::DB {
    has Int  $.id;
    has Str  $.name;
    has Bool $.read-only;
    has Str  $.model;
    has Str  $.comment;
    has Str  $.version;
    has Int  $.records;
    has DateTime $.mod-date;
    has $.data;
    has Agrammon::DB::Tag  @.tags;
    has Agrammon::DB::User $.user;

    method create {
        self.with-db: -> $db {
            my $ds = $db.query(q:to/DATASET/, $!name, $!user.id, $!version, $!comment, $!model, $!read-only);
                INSERT INTO dataset (dataset_name, dataset_pers,
                                     dataset_version, dataset_comment,
                                     dataset_model, dataset_readonly
                                    )
                VALUES ($1, $2, $3, $4, $5, $6)
                RETURNING dataset_id, dataset_mod_date
            DATASET

            my @d = $ds.array;
            $!id = @d[0];
            $!mod-date = @d[1];
        }
        return self;
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
        return self;
    }

    method !clone($new) {
        my $dataset = Agrammon::DB::Dataset.new(:name($new));
        warn "clone($new) not yet implemented";
        return $dataset;
    }

    method submit($email) {
        my $new-dataset = self!clone("Clone of $!name");

        warn "Sending mail for submit($email) not yet implemented";
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


### TOOD: use INSERT ON CONFLICT !!!
    #! Set tag on datasets opportunistically.
    method set-tag(@datasets!, $tag-name!) {
        my $tagged = 0;
        self.with-db: -> $db {
            my $tag-id = Agrammon::DB::Tag.new( :name($tag-name), :$!user).lookup.id;
            die X::Agrammon::DB::Tag::UnknownTag($tag-name) unless $tag-id;

            for @datasets -> $dataset-name {
                my $ds = Agrammon::DB::Dataset.new($!user, $dataset-name).load;
                my @tags = $ds.tags;
                dd @tags.map(*.name);
                $tagged += $db.query(q:to/SQL/, $tag-id, $dataset-name).rows;
                    INSERT INTO tagds (tagds_tag, tagds_dataset)
                            VALUES       ($1, $2)
                    RETURNING tagds_id
                SQL
                CATCH { # ignore unique failures (tag already set)
                    when /unique/ {
                        next;
                    }
                    # other DB failure
                    die X::Agrammon::DB::Dataset::SetTagFailed.new($tag-name);
                }
            }
        }
        return $tagged;
    }

    #! Remove tag from datasets opportunistically.
    method remove-tag(@datasets!, $tag-name) {
        my $deleted = 0;
        self.with-db: -> $db {
            my $tag-id = Agrammon::DB::Tag.new( :name($tag-name), :$!user).lookup.id;
            die X::Agrammon::DB::Tag::UnknownTag($tag-name) unless $tag-id;

            for @datasets -> $dataset-name {
                $deleted += $db.query(q:to/SQL/, $tag-id, $dataset-name).rows;
                    DELETE FROM tagds
                    WHERE tagds_tag = $1 AND tagds_dataset = SELECT dataset_id FROM dataset WHERE dataset_name = $2
                SQL
            }
        }
        return $deleted;
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

            my $rows = $ret.rows;
            return $rows if $rows;
        }
    }

    method !store-input-comment($variable, $comment) {
        my $username = $!user.username;
        self.with-db: -> $db {
                my $ret = $db.query(q:to/SQL/, $comment, $username, $!name, $variable);
                UPDATE data_new SET data_comment = $1
                 WHERE data_dataset=dataset_name2id($2,$3) AND data_var = $4
                                                           AND data_instance IS NULL
                RETURNING data_comment
            SQL

            return if $ret.rows;

            $ret = $db.query(q:to/SQL/, $comment, $username, $!name, $variable);
                INSERT INTO data_new (data_dataset, data_var, data_comment)
                     VALUES          (dataset_name2id($2,$3), $4, $1)
                RETURNING data_comment
                SQL

            # couldn't save comment
            die X::Agrammon::DB::Dataset::StoreInputCommentFailed.new(:$comment, :$variable) unless $ret.rows;
        }
    }

    method !store-instance-input-comment($variable, $instance, $comment) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $comment, $username, $!name, $variable, $instance);
                UPDATE data_new SET data_comment = $1
                 WHERE data_dataset=dataset_name2id($2,$3) AND data_var = $4
                                                           AND data_instance = $5
                RETURNING data_comment
            SQL

            return if $ret.rows;

            $ret = $db.query(q:to/SQL/, $comment, $username, $!name, $variable, $instance);
                INSERT INTO data_new (data_dataset, data_var, data_comment, data_instance)
                     VALUES          (dataset_name2id($2,$3), $4, $1, $5)
                RETURNING data_comment
            SQL

            # couldn't save comment
            die X::Agrammon::DB::Dataset::StoreInputCommentFailed.new(:$comment, :$variable) unless $ret.rows;
        }
    }

    method store-input-comment(:$variable!, :$comment) {
        my $instance;
        if $variable ~~ s/\[(.+)\]/[]/ {
            $instance = $0;
        }

        return $instance ?? self!store-instance-input-comment($variable, $instance, $comment)
                         !! self!store-input-comment($variable, $comment);
    }

    method !store-variable($variable, $value --> Nil) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $value, $username, $!name, $variable);
                UPDATE data_new SET data_val = $1
                 WHERE data_dataset=dataset_name2id($2,$3) AND data_var = $4
                                                           AND data_instance IS NULL
                RETURNING data_val
            SQL

            return if $ret.rows;

            $ret = $db.query(q:to/SQL/, $value, $username, $!name, $variable);
                INSERT INTO data_new (data_dataset, data_var, data_val)
                     VALUES          (dataset_name2id($2,$3), $4, $1)
                RETURNING data_val
            SQL

            die X::Agrammon::DB::Dataset::StoreDataFailed.new($variable) unless $ret.rows;
        }
    }

    method !store-instance-variable($variable, $instance, $value --> Nil) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $value, $username, $!name, $variable, $instance);
                UPDATE data_new SET data_val = $1
                 WHERE data_dataset=dataset_name2id($2,$3) AND data_var = $4
                                                           AND data_instance = $5
                RETURNING data_comment
            SQL

            return if $ret.rows;

            $ret = $db.query(q:to/SQL/, $value, $username, $!name, $variable, $instance);
                INSERT INTO data_new (data_dataset, data_var, data_val, data_instance)
                     VALUES (dataset_name2id($2,$3), $4, $1, $5)
                RETURNING data_comment
            SQL

            die X::Agrammon::DB::Dataset::StoreDataFailed.new($variable) unless $ret.rows;
        }
    }

    method store-input($var-name, $value --> Nil) {
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

            my $rows = $ret.rows;
            return $rows if $rows;
        }
    }

    method delete-instance($variable-pattern, $instance) {
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

    method rename-instance($old-name, $new-name, $pattern) {
        self.with-db: -> $db {
            # old and new name are identical
            die X::Agrammon::DB::Dataset::InstanceRenameFailed.new(:$old-name, :$new-name) if $old-name eq $new-name;

            my $ret = $db.query(q:to/SQL/, $new-name, $!id, "$pattern\%", $old-name);
                UPDATE data_new set data_instance = $1
                 WHERE data_dataset = $2
                   AND data_var LIKE $3
                   AND data_instance = $4
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
        warn "*** order-instance not yet implemented";
        self.with-db: -> $db {

            # my $i = 0;
            # for (@instances) {
            #     my $pattern  = $_;
            #     $pattern     =~ m/(.*)\[(.*)\]/;
            #     my $var      = $1;
            #     my $instance = $2;
            #     $var         = "%$var\[\]%";
            #     # warn "var=$var, instance=$instance";

            #     my $ret = $db.query(q:to/SQL/, $i, $!id, $var, $instance);
            #     UPDATE data_new SET data_instance_order = $1
            #      WHERE data_dataset = $2
            #       AND data_var      LIKE $3
            #       AND data_instance LIKE $4
            #     SQL
            #     $i++;
            # }
        }
        return True;
    }

}
