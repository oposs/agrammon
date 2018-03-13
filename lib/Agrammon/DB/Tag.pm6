use v6;
use Agrammon::DB::User;

class Agrammon::DB::Tag {
    has Str $.name;
    has Int $.id;
    has Agrammon::DB::User $.user;

    method create {
        self.with-db: -> $db {
            my $results = $db.query(q:to/DATASET/, $!name);
                INSERT INTO tag (tag_name)
                VALUES ($1)
                RETURNING tag_id
            DATASET

            $!id = $results.value;
        }
        return self;
    }

}
