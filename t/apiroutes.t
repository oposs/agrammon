use v6;
use Agrammon::Web::APIRoutes;
use Agrammon::Web::Service;

use Cro::HTTP::Client;
use Cro::HTTP::Test;
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
        get-outputs-from-csv => -> $user, Str $simulation-name, Str $dataset-name, Str $csv-data,
        :$model-version, :$variants, :$technical-file,
        :$language, :$format, :$print-only,
        :$include-filters, :$all-filters {
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

subtest 'Run simulation' => {
    test-service rest-api-routes($schema, $fake-store), :$fake-auth, {
        test-given '/run', {
            test post(
                content-type => 'multipart/form-data',
                body => [
                    :simulation('Test'),
                    :dataset('Hochrechnung'),
                    Cro::HTTP::Body::MultiPartFormData::Part.new(
                        headers => [Cro::HTTP::Header.new(
                            :name('Content-type'),
                            :value('text/csv')
                        )],
                        :name('inputs'),
                        :filename('test.csv'),
                        :body-blob('some;test;data'.encode)
                    )
                ]
            ),
            status => 200,
        };
        check-mock $fake-store,
            *.called('get-outputs-from-csv', times => 1);
    }
}

done-testing;

=begin pod

=COPYRIGHT Copyright (c) 2020 by OETIKER+PARTNER AG. All rights reserved.

=AUTHOR S<Fritz Zaucker E<lt>fritz.zaucker@oetiker.chE<gt>>

See C<git blame> for other contributors.

=end pod
