use Cro::APIToken::Middleware;
use Cro::HTTP::Router;
use Cro::OpenAPI::RoutesFromDefinition;
use IO::Path::ChildSecure;

use Agrammon::Web::APITokenManager;
use Agrammon::Web::Service;

#| API session object, which is just a subclass of the Agrammon user object.
#| Since API requests are stateless, no further details are needed.
my class APIUser is Agrammon::DB::User does Cro::HTTP::Auth is export {
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
    my $schema = 'share/agrammon-rest.openapi';
    route {
        if %*ENV<AGRAMMON_DEBUG> {
            before {
                # Consume and re-instate request.
                my $blob = await request.body-blob;
                request.set-body($blob);
                # Dump.
                my $req = ~request;
                try $req ~= $blob.decode('utf-8');
                note "request=$req";
            }
        }
        before AgrammonAPITokenMiddleware.new(manager => get-api-token-manager());

        include rest-api-routes($schema, $ws);
    }
}

sub rest-api-routes (Str $schema, Agrammon::Web::Service $ws) is export {
    openapi $schema.IO, {
        operation 'getLatex', -> APIUser $user, :$technical = 'technical.cfg', :$sort = 'model' {
            content 'text/plain', $ws.get-latex($technical, $sort)
        }

        operation 'getTechnical', -> APIUser $user, :$technical = 'technical.cfg' {
            content 'text/plain', $ws.get-technical($technical);
        }

        operation 'runSimulation', -> APIUser $user {
            request-body 'multipart/form-data' => -> (
                :$simulation!,  :$dataset!, :$inputs!, :$technical='',
                :$model = 'version6', :$variants = 'Base', :$language = 'de', :$accept is header = 'text/plain',
                :$print-only = '', :$include-filters = 'false', :$all-filters = 'false'
            ) {
                my $type = $inputs.content-type;
                if $type ne 'text/csv' {
                    my $error = "Content type is '$type', must be 'text/csv'";
                    bad-request 'application/json', %( :$error );
                }
                else {
                    my $input-data = $inputs.body-text;
                    my $results = $ws.get-outputs-from-csv(
                        $user,
                        ~$simulation, ~$dataset, ~$input-data,
                        :model-version(~$model), :variants(~$variants), :technical-file(~$technical),
                        :language(~$language), :format(~$accept), :print-only(~$print-only),
                        :include-filters($include-filters eq 'true'), :all-filters($all-filters eq 'true')
                    );
                    content ~$accept, supply {
                        emit $results.encode('utf8');
                    };
                }
            }
        }
    }
}
