use Cro::APIToken::Middleware;
use Cro::HTTP::Router;
use Cro::OpenAPI::RoutesFromDefinition;

use Agrammon::DB::User;
use Agrammon::Web::APITokenManager;
use Agrammon::Web::Service;

#| API session object, which is just a subclass of the Agrammon user object.
#| Since API requests are stateless, no further details are needed.
my class APIUser is Agrammon::DB::User does Cro::HTTP::Auth {
}

#| Extends the Cro::APIToken middleware to load the Agrammon user as identified
#| by the metadata associated with the API token.
my class AgrammonAPITokenMiddleware does Cro::APIToken::Middleware {
    method on-valid(Cro::HTTP::Request $request, Cro::APIToken::Token $token --> Cro::HTTP::Message) {
        with $token.metadata<username> -> $username {
            my $api-user = APIUser.new(:$username);
            if $api-user.exists {
                $api-user.load;
                $request.auth = $api-user;
            }
        }
        return $request;
    }
}

sub api-routes(Agrammon::Web::Service $ws) is export {
    route {
        before AgrammonAPITokenMiddleware.new(manager => get-api-token-manager());

        get -> APIUser $user, 'greet' {
            content 'application/json', { message => "Hello $user.firstname()" }
        }

        post -> APIUser $user, 'run' {
            request-body 'multipart/form-data' => -> (:$simulation!, :$dataset!, :$inputs!, :$language = 'de', :$format = 'text/plain', :$prints, :$all-filters = False, :$include-filters = False ) {
                my $type = $inputs.content-type;
                if $type ne 'text/csv' {
                    my $error = "Content type is '$type', must be 'text/csv'";
                    note $error;
                    bad-request 'application/json', %( error => $error );
                }
                else {
                    note "simulation=$simulation, dataset=$dataset, format=$format, prints=$prints";
                    my $data = $inputs.body-text;
                    my $results = $ws.get-outputs-from-csv($user, ~$simulation, ~$dataset, $data, $include-filters, :$language, :$format, :$prints, :$all-filters);
#                    dd $results;
                    content ~$format, supply {
                        emit $results.encode('utf8');
                    };
                }
            }
        }
    }
}



