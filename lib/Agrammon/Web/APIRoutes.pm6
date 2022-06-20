use Cro::APIToken::Middleware;
use Cro::HTTP::Router;
use Cro::OpenAPI::RoutesFromDefinition;
use IO::Path::ChildSecure;

use Agrammon::Web::APITokenManager;
use Agrammon::Web::Service;
use Agrammon::DataSource::JSON;

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

    method on-invalid(Cro::HTTP::Request $request, Cro::APIToken::Token $token) {
        $request.target eq '/openapi.' ~ any(<yaml json>)
                ?? $request
                !! self.Cro::APIToken::Middleware::on-invalid($request, $token)
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

        operation 'getInputTemplate', -> APIUser $user,
                                         :$sort = 'model', :$format = 'json',
                                         :$language = 'de' {
            my $inputs = $ws.get-input-template($sort, $format, $language);
            if not ($format eq 'json' or $format eq 'csv' or $format eq 'text') {
                my $error = "Content type is '$format', must be 'json' or 'csv' or 'text'";
                $format eq 'json'
                        ?? bad-request 'application/json', %( :$error)
                        !! bad-request 'text/plain', $error ~ "\n";
            }
            else {
                my $content-type;
                given $format {
                    when 'json' { $content-type = 'application/json' };
                    when 'text' { $content-type = 'text/plain' };
                    when 'csv'  { $content-type = 'text/csv' };
                }
                content $content-type, $inputs;
            }
        }

        operation 'runSimulation', -> APIUser $user, :$accept is header = 'text/plain' {
            request-body 'multipart/form-data' => -> (
                :$simulation!,  :$dataset!, :$inputs!, :$technical='',
                :$model = 'version6', :$variants = 'Base', :$language = 'de',
                :$print-only = '', :$report-selected = 0,
                :$compact-output = 'true',
                :$include-filters = 'false', :$all-filters = 'false'
            ) {
                my $type = $inputs.content-type;
                if not ($type eq 'application/json' or $type eq 'text/csv' or $type eq 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
                    my $error = "Content type is '$type', must be 'application/json', 'text/csv' or 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'";
                    $accept eq 'application/json'
                        ?? bad-request 'application/json', %( :$error )
                        !! bad-request 'text/plain', $error ~ "\n";
                }
                else {
                    my $input-data = $inputs.body-text;
                    my $results = $ws.get-outputs-for-rest(
                        ~$simulation, ~$dataset, $input-data, ~$type,
                        :model-version(~$model), :variants(~$variants), :technical-file(~$technical),
                        :language(~$language), :format($accept), :print-only(~$print-only), :$user, :report-selected(~$report-selected),
                        :$compact-output,
                        :include-filters($include-filters eq 'true'), :all-filters($all-filters eq 'true')
                    );
                    if $accept eq 'application/json' {
                        content $accept, %(
                            outputs => @($results),
                            model => %(
                                version => ~$model,
                                technical => ~$technical,
                                variants => ~$variants
                            )
                        )
                    }
                    elsif $accept eq 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' {
                        header 'Content-disposition', qq{attachment; filename="excelReport.xlsx"};
                        content 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', $results.to-blob;
                    }
                    else {
                        content $accept, $results
                    }
                }
            }
        }
    }
}
