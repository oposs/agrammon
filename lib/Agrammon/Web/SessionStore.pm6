use Agrammon::Web::SessionUser;
use Cro::HTTP::Session::Pg;
use JSON::Fast;

#| Postgres-backed session store for the Agrammon web application.
class Agrammon::Web::SessionStore does Cro::HTTP::Session::Pg[Agrammon::Web::SessionUser] {
    method new(*%defaults) {
        nextwith |%defaults,
                cookie-name => 'agrammon',
                sessions-table => 'session',
                id-column => 'session_id',
                state-column => 'session_state',
                expiration-column => 'session_expiration'
    }

    method serialize(Agrammon::Web::SessionUser $s) {
        to-json $s.to-json
    }

    method deserialize(Str $d) {
        Agrammon::Web::SessionUser.from-json(from-json $d)
    }
}
