use v6;
use Agrammon::Web::APIRoutes;
use Agrammon::Web::Service;

use Cro::HTTP::Client;
use Cro::HTTP::Test;
use Cro::HTTP::Router;
use Cro::OpenAPI::RoutesFromDefinition;

use JSON::Fast;
use Test::Mock;
use Test;

# routing tests related to REST API

sub make-fake-auth {
    mocked(APIUser)
}
my $schema = 'share/agrammon-rest.openapi';

my $fake-auth = make-fake-auth;
my $fake-store = mocked(Agrammon::Web::Service,
    returning => {
    },
    overriding => {
        get-input-template => -> $sort, $format, $language {
            given $format {
                when 'json' { to-json %() } ;
                when 'csv'  { "module;variable;" } ;
                when 'text' { "module\n\tvariable" } ;
            }
        },
        get-outputs-for-rest => -> Str $simulation-name, Str $dataset-name, Str $csv-data, $type,
                                       :$model-version, :$variants, :$technical-file,
                                       :$language, :$format, :$print-only,
                                        :$include-filters, :$all-filters, :$compact-output {
            "Test results"
        },
    }
);

subtest 'Get technical file' => {
    test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
        test-given '/model/technical', {
            test get,
                status => 200,
        };
        check-mock $fake-store,
            *.called('get-technical', times => 1);
    }
}

subtest 'Get LaTeX' => {
    test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
        test-given '/model/latex', {
            test get,
                status => 200,
        };
        check-mock $fake-store,
            *.called('get-latex', times => 1);
    }
}

subtest 'Get input template ...' => {
    subtest '... as JSON' => {
        test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
            test-given '/inputTemplate?format=json', {
                test get,
                    status => 200,
                    content-type => 'application/json',
            };
            check-mock $fake-store,
                *.called('get-input-template', times => 1);
        }
    }

    subtest '... as CSV' => {
        test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
            test-given '/inputTemplate?format=csv', {
                test get,
                    status => 200,
                    content-type => 'text/csv',
            };
            check-mock $fake-store,
                    *.called('get-input-template', times => 2);
        }
    }

    subtest '... as TEXT' => {
        test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
            test-given '/inputTemplate?format=text', {
                test get,
                    status => 200,
                    content-type => 'text/plain',
            };
            check-mock $fake-store,
                    *.called('get-input-template', times => 3);
        }
    }
}

sub make-body(%fields?) {
    [
        :simulation('Test'),
        :dataset('Hochrechnung'),
        Cro::HTTP::Body::MultiPartFormData::Part.new(
            headers => [
                Cro::HTTP::Header.new(
                    :name('Content-type'),
                    :value('text/csv')
                )
            ],
            :name('inputs'),
            :filename('test.csv'),
            :body-blob('some;test;data'.encode)
        ),
        |%fields
    ]
}

subtest 'Run simulation' => {

    subtest 'Required parameters' => {
        test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
            test-given '/run', {
                test post(
                    :content-type('multipart/form-data'),
                    :body(make-body(%{}))
                ),
                status => 200,
            };
            check-mock $fake-store,
            *.called('get-outputs-for-rest', times => 1);
        }
    }

    subtest 'Correct optional parameters' => {
        test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
            test-given '/run', {
                test post(
                    :content-type('multipart/form-data'),
                    :body(
                        make-body(
                            %{
                                :language('en'),
                                :model('version6'),
                                :variants('Base'),
                            }
                        )
                    )
                ),
                status => 200,
            };
            check-mock $fake-store,
                *.called('get-outputs-for-rest', times => 2);
        }
    }

    subtest 'Invalid optional parameters' => {
        test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
            test-given '/run', {
                test post(:content-type('multipart/form-data'),
                          :body(make-body(%{
                                                 :model('version3'),
                                                 :variants('Base'),
                                                 :invalid('Testing'),
                                             }
                                         )
                               )
                         ),
                status => 400,
            };
            check-mock $fake-store,
                *.called('get-outputs-for-rest', times => 2);
        }
    }

    subtest 'Invalid language' => {
        test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
            test-given '/run', {
                test post(:content-type('multipart/form-data'),
                          :body(make-body(%{
                                                 :language('invalid'),
                                           }
                                         )
                               )
                         ),
                status => 400,
            };
            check-mock $fake-store,
                *.called('get-outputs-for-rest', times => 2);
        }
    }

    subtest 'Invalid model' => {
        test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
            test-given '/run', {
                test post(:content-type('multipart/form-data'),
                          :body(make-body(%{
                                                 :model('invalid'),
                                             }
                                         )
                               )
                         ),
                status => 400,
            };
            check-mock $fake-store,
                *.called('get-outputs-for-rest', times => 2);
        }
    }

    subtest 'Invalid variant' => {
        test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
            test-given '/run', {
                test post(:content-type('multipart/form-data'),
                          :body(make-body(%{
                                                 :variant('invalid'),
                                             }
                                         )
                               )
                         ),
                status => 400,
            };
            check-mock $fake-store,
                *.called('get-outputs-for-rest', times => 2);
        }
    }
}

done-testing;

=begin pod

=COPYRIGHT Copyright (c) 2021 by OETIKER+PARTNER AG. All rights reserved.

=AUTHOR S<Fritz Zaucker E<lt>fritz.zaucker@oetiker.chE<gt>>

See C<git blame> for other contributors.

=end pod
