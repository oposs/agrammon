use v6;
use Agrammon::DB;
use Agrammon::DB::User;

#| Error when a tag already exists for the user.
class X::Agrammon::DB::Tag::AlreadyExists is Exception {
    has Str $.name is required;
    method message {
        "Tag '$!name' already exists."
    }
}

#| Error when tag couldn't be renamed.
class X::Agrammon::DB::Tag::RenameFailed is Exception {
    has Str $.old-name is required;
    has Str $.new-name is required;
    method message {
        "Tag '$!old-name' couldn't be renamed to '$!new-name'."
    }
}

#| Error when tag couldn't be created.
class X::Agrammon::DB::Tag::CreateFailed is Exception {
    has Str $.name is required;
    method message {
        "Tag '$!name' couldn't be created."
    }
}

#| Error when tag couldn't be deleted.
class X::Agrammon::DB::Tag::DeleteFailed is Exception {
    has Str $.name is required;
    method message {
        "Tag '$!name' couldn't be deleted."
    }
}

class Agrammon::DB::Tag does Agrammon::DB {
    has Str $.name;
    has Int $.id;
    has Agrammon::DB::User $.user;

    method create {
        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $!name, $!user.id);
                INSERT INTO tag (tag_name, tag_pers)
                VALUES ($1, $2)
                RETURNING tag_id
            SQL

            # new dataset name already exists
            CATCH {
                when /unique/ {
                    die X::Agrammon::DB::Tag::AlreadyExists.new(:$!name);
                }
            }

            # update failed
            die X::Agrammon::DB::Tag::CreateFailed.new(:$!name) unless $ret.value;

            # rename suceeded
            $!id = $ret.value;
        }
        return self;
    }

    method rename($new) {
        self.with-db: -> $db {
            # old and new name are identical
            die X::Agrammon::DB::Tag::RenameFailed.new(:old-name($!name), :new-name($new)) if $new eq $!name;

            my $ret = $db.query(q:to/SQL/, $new, $!name, $!user.id);
                UPDATE tag SET tag_name = $1
                 WHERE tag_name = $2 AND tag_pers = $3
                RETURNING tag_name
            SQL

            # new dataset name already exists
            CATCH {
                when /unique/ {
                    die X::Agrammon::DB::Tag::AlreadyExists.new(:$!name);
                }
            }

            # update failed
            die X::Agrammon::DB::Tag::RenameFailed.new(:old-name($!name), :new-name($new)) unless $ret.rows;

            # rename suceeded
            $!name = $new;
        }
        return self.name;
    }

   method delete {
        self.with-db: -> $db {
            my $ret = $db.query(q:to/TAG/, $!id);
                DELETE FROM tag
                 WHERE tag_id = $1
                RETURNING tag_id
            TAG

            # delete failed
            die X::Agrammon::DB::Tag::DeleteFailed.new( :$!name ) unless $ret.rows;
        }
    }

    method lookup {
        self.with-db: -> $db {
            my $username = $!user.username;
            my $results = $db.query(q:to/TAG/, $!user.id, $!name);
            SELECT tag_id
              FROM tag LEFT JOIN pers ON tag_pers=pers_id
             WHERE tag_pers = $1
               AND tag_name = $2
            TAG
            $!id = $results.value;
        }
        return self;
    }

}
