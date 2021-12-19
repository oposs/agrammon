use v6;

use Text::CSV;
use Agrammon::DB::Tag;
use Agrammon::DB::User;
use Agrammon::DB::Variant;

#| Error when a dataset already exists for the user.
class X::Agrammon::DB::Dataset::AlreadyExists is Exception {
    has Str $.dataset-name is required;
    method message {
        "Dataset '$!dataset-name' already exists."
    }
}

#| CSV format error during dataset upload by user.
class X::Agrammon::DB::Dataset::UploadCSVError is Exception {
    has Str $.dataset-name is required;
    has Str $.msg is required;
    method message {
        "CSV format error, dataset '$!dataset-name' couldn't be uploaded: $!msg"
    }
}

#| Database error during dataset upload by user.
class X::Agrammon::DB::Dataset::UploadDatabaseFailure is Exception {
    has Str $.dataset-name is required;
    has Str $.msg is required;
    method message {
        "Database failure, dataset '$!dataset-name' couldn't be uploaded: $!msg"
    }
}

#| Unknown failure during dataset upload by user.
class X::Agrammon::DB::Dataset::UploadUnknowFailure is Exception {
    has Str $.dataset-name is required;
    has Str $.msg is required;
    method message {
        "Unknown failure, dataset '$!dataset-name' couldn't be uploaded: $!msg"
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

#| Error when input comment couldn't be stored.
class X::Agrammon::DB::Dataset::StoreInputCommentFailed is Exception {
    has Str $.comment is required;
    has Str $.variable is required;
    method message {
        "Couldn't store comment '$!comment' for variable '$!variable'."
    }
}

#| Error when dataset comment couldn't be stored.
class X::Agrammon::DB::Dataset::StoreDatasetCommentFailed is Exception {
    has Str $.comment is required;
    has Str $.dataset is required;
    method message {
        "Couldn't stored comment '$!comment' for dataset '$!dataset'."
    }
}

#| Error when data couldn't be saved.
class X::Agrammon::DB::Dataset::StoreDataFailed is Exception {
    has Str $.variable is required;
    method message {
        "Data for variable '$!variable' couldn't be saved."
    }
}

#| Error when branching data was passed when storing a none-instance variable.
class X::Agrammon::DB::Dataset::InvalidBranchData is Exception {
    has Str $.variable is required;
    method message {
        "Unexpected branching data for none-instance variable '$!variable'."
    }
}

#| Error when branching data couldn't be saved.
class X::Agrammon::DB::Dataset::StoreBranchDataFailed is Exception {
    has Str $.variable is required;
    method message {
        "Branching data for variable '$!variable' couldn't be saved."
    }
}

#| Error when tag couldn't be set.
class X::Agrammon::DB::Dataset::SetTagFailed is Exception {
    has Str $.tag-name is required;
    has Str $.dataset-name is required;
    method message {
        "Tag '$!tag-name' couldn't be set on dataset '$!dataset-name'."
    }
}

#| Error when tag couldn't be removed.
class X::Agrammon::DB::Dataset::RemoveTagFailed is Exception {
    has Str $.tag-name is required;
    method message {
        "Tag '$!tag-name' couldn't be removed."
    }
}

class Agrammon::DB::Dataset does Agrammon::DB::Variant {
    has Int  $.id;
    has Str  $.name;
    has Bool $.read-only;
    has Bool $.is-demo;
    has Str  $.model;
    has Str  $.comment;
    has Int  $.records; # this is set in Agrammon::DB::Datasets.load
    has DateTime $.mod-date;
    has DateTime $.created;
    has $.data;
    has Agrammon::DB::Tag  @.tags;
    has Agrammon::DB::User $.user;

    method !create-dataset( $dataset-name, $username, $comment? ) {
        my @ret;
        self.with-db: -> $db {
            @ret = $db.query(q:to/SQL/, $username, $dataset-name, |self!variant, $comment).array;
                INSERT INTO dataset (dataset_name, dataset_pers,
                                     dataset_version, dataset_guivariant, dataset_modelvariant,
                                     dataset_comment)
                  SELECT $2, pers_id,
                         $3, $4, $5,
                         $6
                    FROM pers
                   WHERE pers_email = $1
                RETURNING dataset_id, dataset_name, dataset_mod_date, dataset_created
            SQL
            CATCH {
                .note;
                # new dataset name already exists
                when /unique/ {
                    die X::Agrammon::DB::Dataset::AlreadyExists.new(:$dataset-name);
                }
            }
        }
        return { :id(@ret[0]), :name(@ret[1]), :mod-date(@ret[2]), :created(@ret[3]) };
    }

    method create {
        my $ds = self!create-dataset( $!name, $!user.username, $!comment );
        $!id = $ds<id>;
        $!mod-date = $ds<mod-date>;
        $!created = $ds<created>;
        return self;
    }

    method clone(:$old-username, :$new-username, :$old-dataset, :$new-dataset) {
        note "clone(): old-username=$old-username, new-username=$new-username, old-dataset=$old-dataset, new-dataset=$new-dataset";
        $old-username //= $!user.username;

        # old and new dataset are identical
        die X::Agrammon::DB::Dataset::AlreadyExists.new(:dataset-name($new-dataset))
            if $old-dataset eq $new-dataset and $old-username eq $new-username;

        my $ds = self!create-dataset( $new-dataset, $new-username);
        self.with-db: -> $db {
            # clone inputs
            $db.query(q:to/SQL/, $ds<id>, $old-username, $old-dataset, |self!variant);
                INSERT INTO data_new (data_dataset, data_var, data_instance, data_val, data_instance_order, data_comment)
                     SELECT $1, data_var, data_instance, data_val, data_instance_order, data_comment
                       FROM data_new
                      WHERE data_dataset = dataset_name2id($2, $3, $4, $5, $6)
            SQL

            # get branched inputs from new dataset
            my @rows = $db.query(q:to/SQL/, $ds<id>).arrays;
            SELECT data_id
              FROM data_new LEFT JOIN branches ON (branches_var=data_id)
             WHERE data_dataset=$1
               AND data_val = 'branched'
             ORDER BY data_instance, data_id -- don't change sort order!!!
            SQL

            # get branch data from old dataset
            my @data = $db.query(q:to/SQL/, $old-username, $old-dataset, |self!variant).arrays;
                SELECT branches_data, branches_options, data_var
                  FROM data_new LEFT JOIN branches ON (branches_var=data_id)
                 WHERE data_dataset = dataset_name2id($1,$2,$3,$4,$5) AND branches_data is not null
              ORDER BY data_instance, data_id -- don't change sort order!!!
            SQL

            # clone branching data (rows from new and data from old dataset)
            for flat @data Z @rows -> $data, $row {
                $db.query(q:to/SQL/, $row, $data[0], $data[1]);
                    INSERT INTO branches (branches_var, branches_data, branches_options)
                       VALUES ($1, $2, $3)
                SQL
            }

            CATCH {
                .note;
                die X::Agrammon::DB::Dataset::CloneFailed.new(:$old-username, :$new-username, :$old-dataset, :$new-dataset);
            }
        }
        return $ds;
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
                .note;
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

        # TODO: move here from Routes.pm
        warn "Submitting dataset and sending mail for submit($email) not yet implemented";
        return $new-dataset;
    }

    method lookup {
        self.with-db: -> $db {
            my $username = $!user.username;
            my $results = $db.query(q:to/SQL/, $username, $!name, |self!variant);
                SELECT dataset_name2id($1,$2,$3,$4,$5)
            SQL
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
                my $ds-id = Agrammon::DB::Dataset.new(
                    :$!user,
                    :%!agrammon-variant,
                    :name($dataset-name)
                ).lookup.id;
                $db.query(q:to/SQL/, $tag-id, $ds-id);
                    INSERT INTO tagds (tagds_tag, tagds_dataset)
                         VALUES       ($1, $2)
                    ON CONFLICT (tagds_tag, tagds_dataset) DO NOTHING
                SQL
                CATCH {
                    # other DB failure
                    .note;
                    die X::Agrammon::DB::Dataset::SetTagFailed.new(:$dataset-name, :$tag-name);
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
                    .note;    
                    die X::Agrammon::DB::Dataset::RemoveTagFailed.new(:$tag-name);
                }
            }
        }
    }

    method load {
        self.with-db: -> $db {
            my $username = $!user.username;
            my $results = $db.query(q:to/DATASET/, $username, $!name,  |self!variant);
            SELECT data_var, data_val, data_instance_order, branches_data, data_comment
              FROM data_view LEFT JOIN branches ON (branches_var=data_id)
             WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5)
               AND data_var not like '%::ignore'
             ORDER BY data_instance_order ASC, data_var
            DATASET
            $!data = $results.arrays;
        }
        return self;
    }

    method upload-data($content) {
        my $fh = IO::String.new($content);
        my $csv = Text::CSV.new;
        my $i = 0;
        while (my @row = $csv.getline($fh)) {
            my ($var-name, $value) = @row;
            next unless $var-name;
            # skip comments
            next if $var-name ~~ /^\#/;
            self.store-input($var-name, $value);
            $i++;
        }
        CATCH {
            .note;
            when CSV::Diag {
                die X::Agrammon::DB::Dataset::UploadCSVError.new(:dataset-name($!name), :msg(.message));
            }
            when X::Agrammon::DB::Dataset::StoreDataFailed {
                die X::Agrammon::DB::Dataset::UploadDatabaseFailure.new(:dataset-name($!name), :msg(.message));
            }
            default {
                die X::Agrammon::DB::Dataset::UploadUnknowFailure.new(:dataset-name($!name), :msg(.message));
            }
        }
        return $i;
    }

    method store-comment($comment) {

        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $comment, $username, $!name, |self!variant);
            UPDATE dataset SET dataset_comment = $1, dataset_mod_date = CURRENT_TIMESTAMP
             WHERE dataset_id=dataset_name2id($2,$3,$4,$5,$6)
            RETURNING dataset_comment
            SQL
            $!comment = $comment || Nil;

            # couldn't save comment
            die X::Agrammon::DB::Dataset::StoreDatasetCommentFailed.new(:$comment, :dataset($!name)) unless $ret.rows;

            return $ret.rows;
        }
    }

    method !store-variable-comment($variable, $comment) {
        my $username = $!user.username;
        self.with-db: -> $db {
                my $ret = $db.query(q:to/SQL/, $comment, $username, $!name, |self!variant, $variable);
                UPDATE data_new SET data_comment = $1
                 WHERE data_dataset=dataset_name2id($2,$3,$4,$5,$6) AND data_var = $7
                                                                    AND data_instance IS NULL
                RETURNING data_comment
            SQL
            return $ret.rows if $ret.rows;

            $ret = $db.query(q:to/SQL/, $comment, $username, $!name, |self!variant, $variable);
                INSERT INTO data_new (data_dataset, data_var, data_comment)
                     VALUES          (dataset_name2id($2,$3,$4,$5,$6), $7, $1)
                RETURNING data_comment
                SQL

            # couldn't save comment
            die X::Agrammon::DB::Dataset::StoreInputCommentFailed.new(:$comment, :$variable) unless $ret.rows;

            $db.query(q:to/SQL/, $!user.username, $!name, |self!variant);
                    UPDATE dataset SET dataset_mod_date = CURRENT_TIMESTAMP
                     WHERE dataset_id=dataset_name2id($1,$2,$3,$4,$5)
            SQL
            return $ret.rows;
        }
    }

    method !store-instance-variable-comment($variable, $instance, $comment) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $comment, $username, $!name, |self!variant, $variable, $instance);
                UPDATE data_new SET data_comment = $1
                 WHERE data_dataset=dataset_name2id($2,$3,$4,$5,$6)
                   AND data_var      = $7
                   AND data_instance = $8
                RETURNING data_comment
            SQL
            return $ret.rows if $ret.rows;

            $ret = $db.query(q:to/SQL/, $comment, $username, $!name, |self!variant, $variable, $instance);
                INSERT INTO data_new (data_dataset, data_var, data_comment, data_instance)
                              VALUES (dataset_name2id($2,$3,$4,$5,$6), $7, $1, $8)
                RETURNING data_comment
            SQL

            # couldn't save comment
            die X::Agrammon::DB::Dataset::StoreInputCommentFailed.new(:$comment, :$variable) unless $ret.rows;

            $db.query(q:to/SQL/, $!user.username, $!name, |self!variant);
                    UPDATE dataset SET dataset_mod_date = CURRENT_TIMESTAMP
                     WHERE dataset_id=dataset_name2id($1,$2,$3,$4,$5)
            SQL
            return $ret.rows;
        }
    }

    method store-input-comment($var-name, $comment) {
        my $instance;
        my $var = $var-name;
        if $var ~~ s/\[(.+)\]/[]/ {
            $instance = $0;
        }

        $instance ?? self!store-instance-variable-comment($var, $instance, $comment)
                  !! self!store-variable-comment($var, $comment);

        self.with-db: -> $db {
            $db.query(q:to/SQL/, $!user.username, $!name, |self!variant);
                    UPDATE dataset SET dataset_mod_date = CURRENT_TIMESTAMP
                     WHERE dataset_id=dataset_name2id($1,$2,$3,$4,$5)
            SQL
        }
    }

    method !store-variable($variable, $value) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $value, $username, $!name, |self!variant, $variable);
                UPDATE data_new SET data_val = $1
                 WHERE data_dataset=dataset_name2id($2,$3,$4,$5,$6) AND data_var = $7
                                                                    AND data_instance IS NULL
                RETURNING data_val
            SQL
            return $ret.rows if $ret.rows;

            $ret = $db.query(q:to/SQL/, $value, $username, $!name, |self!variant, $variable);
                INSERT INTO data_new (data_dataset, data_var, data_val)
                     VALUES          (dataset_name2id($2,$3,$4,$5,$6), $7, $1)
                RETURNING data_val
            SQL

            # couldn't store variable
            die X::Agrammon::DB::Dataset::StoreDataFailed.new($variable) unless $ret.rows;

            return $ret.rows;
        }
    }

    method !store-instance-variable($variable, $instance, $value, @branches?, @options?) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $value, $username, $!name, |self!variant, $variable, $instance);
                UPDATE data_new SET data_val = $1
                 WHERE data_dataset=dataset_name2id($2,$3,$4,$5,$6) AND data_var = $7
                                                                    AND data_instance = $8
                RETURNING data_id
            SQL

            $ret = $db.query(q:to/SQL/, $value, $username, $!name, |self!variant, $variable, $instance) unless $ret.rows;
                INSERT INTO data_new (data_dataset, data_var, data_val, data_instance)
                     VALUES (dataset_name2id($2,$3,$4,$5,$6), $7, $1, $8)
                RETURNING data_id
            SQL

            # couldn't store variable
            die X::Agrammon::DB::Dataset::StoreDataFailed.new($variable) unless $ret.rows;

            if @branches {
                my $data-id = $ret.value;
                $ret = $db.query(q:to/SQL/, $data-id, @branches[*;*], @options);
                    INSERT INTO branches (branches_var, branches_data, branches_options)
                         VALUES ($1, $2, $3)
                    RETURNING branches_id
                SQL

                die X::Agrammon::DB::Dataset::StoreBranchDataFailed.new($variable) unless $ret.rows;
            }

            return $ret.rows;
        }
    }

    method store-input($variable, $value, @branches?, @options?) {
        my $instance;

        my $var = $variable;
        if $var ~~ s/\[(.+)\]/[]/ {
            $instance = $0;
        }

        if $instance {
            self!store-instance-variable($var, $instance, $value, @branches, @options);
        }
        else {
            die X::Agrammon::DB::Dataset::InvalidBranchData.new(:$variable) if @branches or @options;
            self!store-variable($var, $value);
        }

        self.with-db: -> $db {
            $db.query(q:to/SQL/, $!user.username, $!name, |self!variant);
                    UPDATE dataset SET dataset_mod_date = CURRENT_TIMESTAMP
                     WHERE dataset_id=dataset_name2id($1,$2,$3,$4,$5)
            SQL
        }
    }

    method !delete-variable($var) {

        return unless $var;
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $username, $!name, |self!variant, $var);
            DELETE FROM data_new
             WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5) AND data_var=$6
                                                                AND data_instance IS NULL
            RETURNING data_val
            SQL

            return $ret.rows;
        }
    }

    method delete-instance($variable-pattern, $instance --> Nil) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $username, $!name, |self!variant, $variable-pattern ~ '%', $instance);
                DELETE FROM data_new
                 WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5) AND data_var LIKE $6
                                                                    AND data_instance = $7
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

            my $ret = $db.query(q:to/SQL/, $new-name, $username, $!name, |self!variant, "$pattern\%", $old-name);
                UPDATE data_new set data_instance = $1
                 WHERE data_dataset = dataset_name2id($2,$3,$4,$5,$6)
                   AND data_var LIKE $7
                   AND data_instance = $8
                RETURNING data_val
            SQL

            # new instance name already exists
            CATCH {
                .note;
                when /unique/ {
                    die X::Agrammon::DB::Dataset::InstanceAlreadyExists.new(:name($new-name));
                }
            }

            # update failed
            die X::Agrammon::DB::Dataset::InstanceRenameFailed.new(:$old-name, :$new-name) unless $ret.rows;
        }
    }

    method order-instances(@instances) {
        my $username = $!user.username;

        self.with-db: -> $db {
            for @instances.kv -> $i, $pattern {
                $pattern     ~~ / (.+) '[' (.+) ']' /;
                my $var      = $0;
                my $instance = $1;
                $var         = "$var\[\]%";
                $db.query(q:to/SQL/, $i, $username, $!name, |self!variant, $var, $instance);
                UPDATE data_new SET data_instance_order = $1
                 WHERE data_dataset = dataset_name2id($2,$3,$4,$5,$6)
                   AND data_var     LIKE $7
                   AND data_instance = $8
                RETURNING data_instance_order
                SQL
            }
        }

        # reordering failed
        CATCH {
            .note;
            die X::Agrammon::DB::Dataset::InstanceReorderFailed.new(:$!name);
        }
    }

    method store-branch-data(@vars, Str $instance, %options, @fractions) {
        my $dataset-name = $!name;

        my @branch-variables;
        # Get variable ids and names
        self.with-db: -> $db {
            my $username = $!user.username;
            @branch-variables = $db.query(q:to/SQL/, $username, $dataset-name, |self!variant, |@vars, $instance).hashes;
            SELECT data_id, data_var
                  FROM data_new
                 WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5)
                   AND data_var IN ($6,$7)
                   AND data_instance = $8
                   ORDER BY data_instance, data_id
            SQL
        }

        for @branch-variables -> %var {
            my $var-id   = %var<data_id>;
            my $var-name = %var<data_var>;

            my @options = %options{$var-name}.map(*.subst(' ', '_', :g) );
            self.with-db: -> $db {
                my $ret = $db.query(q:to/SQL/, $var-id, @fractions[*;*], @options);
                    INSERT INTO branches (branches_var, branches_data, branches_options)
                                  VALUES ($1, $2, $3)
                    ON CONFLICT (branches_var)
                    DO
                        UPDATE SET branches_data    = EXCLUDED.branches_data,
                                   branches_options = EXCLUDED.branches_options
                    SQL
                die X::Agrammon::DB::Dataset::StoreBranchDataFailed.new(:variable($var-name)) unless $ret;
            }
        }

        self.with-db: -> $db {
            $db.query(q:to/SQL/, $!user.username, $dataset-name, |self!variant);
                    UPDATE dataset SET dataset_mod_date = CURRENT_TIMESTAMP
                     WHERE dataset_id=dataset_name2id($1,$2,$3,$4,$5)
                SQL
        }
    }

    method load-branch-data(@var-names, Str $instance) {
        my $data;
        self.with-db: -> $db {
            my $username = $!user.username;
            my @vars = $db.query(q:to/SQL/, $username, $!name, |self!variant, |@var-names, $instance).arrays;
                SELECT data_id
                  FROM data_new
                 WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5)
                   AND data_var IN ($6,$7)
                   AND data_instance = $8
                 ORDER BY data_id
            SQL

            my $branches = $db.query(q:to/SQL/, |@vars[*;*]).hashes;
                SELECT branches_data, branches_options
                  FROM branches
                 WHERE branches_var in ($1,$2)
                 ORDER BY branches_id
            SQL
            $data = {
                fractions => $branches[0]<branches_data>,
                options   => [ $branches[0]<branches_options>, $branches[1]<branches_options> ]
            };
        }
        return $data;
    }

}
