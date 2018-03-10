use v6;
use Agrammon::DB::User;
use Agrammon::Web::UserSession;

class Agrammon::DB::Dataset {
    has Int  $.id;
    has Str  $.name;
    has Bool $.read-only;
    has Str  $.model;
    has Str  $.comment;
    has Str  $.version;
    has DateTime $.mod-date;
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

    method load {
        ...
        return self;
    }

    method data {
        ...
    }
    
}
