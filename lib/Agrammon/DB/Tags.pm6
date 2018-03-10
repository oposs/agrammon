use v6;
use Agrammon::DB;
use Agrammon::DB::User;
use Agrammon::DB::Tag;
use Agrammon::Web::UserSession;

class Agrammon::DB::Tags  does Agrammon::DB {
    has Agrammon::DB::User $.user;
    has Agrammon::DB::Tag  @.collection;
    
    method load {
        self.with-db: -> $db {
            my $username = $!user.username;
            my $results = $db.query(q:to/TAGS/, $username);
                SELECT tag_id AS id,
                       tag_name AS name
                  FROM tag
                 WHERE tag_pers=pers_email2id($1)
                ORDER BY tag_name
            TAGS

            for $results.hashes -> $dh {
                my $tag = Agrammon::DB::Tag.new(|$dh);
                @!collection.push($tag);
            }
        }
        return self;
    }
    
    method list {
        return [@!collection.map: {.id, .name}];
    }
    
}
