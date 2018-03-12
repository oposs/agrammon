use v6;
use Cro::HTTP::Auth;
use Agrammon::DB::User;

class Agrammon::Web::SessionUser is Agrammon::DB::User does Cro::HTTP::Auth {

    method logged-in() {
        return defined self.username;
    }

}
