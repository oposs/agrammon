use v6;
use Agrammon::DB;
use Agrammon::DB::User;

class Agrammon::DB::Tag does Agrammon::DB {
    has Str $.name;
    has Int $.id;
    has Agrammon::DB::User $.user;

    method create {
        self.with-db: -> $db {
            my $results = $db.query(q:to/TAG/, $!name, $!user.id);
                INSERT INTO tag (tag_name, tag_pers)
                VALUES ($1, $2)
                RETURNING tag_id
            TAG

            $!id = $results.value;
        }
        return self;
    }

    method rename($new) {
        self.with-db: -> $db {
            $db.query(q:to/TAG/, $new, $!name, $!user.id);
                UPDATE tag SET tag_name = $1
                 WHERE tag_name = $2 AND tag_pers = $3
                RETURNING tag_name
            TAG
            $!name = $new;
        }
        return self;
    }

   method delete {
        self.with-db: -> $db {
            $db.query(q:to/TAG/, $!id);
                DELETE FROM tag
                 WHERE tag_id = $1
            TAG
        }
        return self;
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
