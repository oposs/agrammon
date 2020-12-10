use Agrammon::Web::Routes;
use Agrammon::Web::Service;
use Agrammon::Web::SessionUser;
use Spreadsheet::XLSX;

use Cro::HTTP::Test;
use Test::Mock;
use Test;

plan 14;

# routing tests related to application logic

sub make-fake-auth($role) {
    mocked(
        Agrammon::Web::SessionUser,
        returning => { :id(42), :logged-in, }
    )
}

my $role = 'user';
my $fake-auth = make-fake-auth($role);

my $fake-store = mocked(Agrammon::Web::Service,
    returning => {
        get-cfg =>  %( :title('Agrammon'), :version('SHL') ),
        load-branch-data => ( 1, 2 ),
    },
    overriding => {
        get-input-variables => {
            %(
                inputs  => [
                    {
                        :variable("Livestock::DairyCow[]::Excretion::CMilk::milk_yield")
                    },
                ],
                graphs  => [],
                reports => [],
            ),
        },
        get-output-variables => -> $user, $dataset-name {
            %( :variable('x'), :value(2) )
        },
        get-pdf-export => -> $user, %params {
        },
        get-excel-export => -> $user, %params {
            Spreadsheet::XLSX.new;
        },
        delete-instance => -> $user, $dataset-name, $instance, $pattern {
        },
        rename-instance => -> $user, $dataset-name, $old-name, $new-name, $variable-pattern {
        },
        order-instances => -> $user, $dataset-name, @instances {
            %( sorted => 1 )
        },
        store-branch-data => -> $user, %data, $dataset-name {
            %( stored => 1 )
        },
        store-input-comment => -> $user, $dataset-name, $variable, $comment {
        },
        store-data => -> $user, $dataset, $variable, $value, @branches?, @options?, $row? {
        },
    }
);

subtest 'Get configuration without login' => {
    test-service routes($fake-store), {
        test post( '/get_cfg'),
            status => 200,
            json   => { title => 'Agrammon', version => 'SHL' };
        check-mock $fake-store,
            *.called('get-cfg', times => 1);
    }
}

subtest 'Get configuration with login' => {
    test-service routes($fake-store), :$fake-auth, {
        test post( '/get_cfg'),
            status => 200,
            json   => { title => 'Agrammon', version => 'SHL' };
        check-mock $fake-store,
            *.called('get-cfg', times => 2);
    }
}

subtest 'Get input variables' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/get_input_variables', {
            test post(json => { :datasetName('DatasetA') } ),
            status => 200,
            json   => {
                datasetName => 'DatasetA',
                inputs  => [
                    {
                        :variable("Livestock::DairyCow[]::Excretion::CMilk::milk_yield")
                    },
                ],
                graphs  => [],
                reports => [],
            }
        };
        check-mock $fake-store,
            *.called('get-input-variables', times => 1);
    }
}

subtest 'Get output variables' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/get_output_variables', {
            test post(json => { :datasetName('DatasetA') } ),
                    status => 200,
                    json   => { :variable('x'), :value(2) }
        };
        check-mock $fake-store,
                *.called('get-output-variables', times => 1);
    }
}

subtest 'Get excel export' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/export/excel', {
            test post(
                    content-type => 'application/x-www-form-urlencoded',
                    body => {
                        :datasetName('TestSingle'),
                        :language('de'),
                    }),
                    status => 200;
        };
        check-mock $fake-store,
                *.called('get-excel-export', times => 1);
    }
}

subtest 'Get PDF report' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/export/pdf', {
            test post(
                    content-type => 'application/x-www-form-urlencoded',
                    body => {
                        :datasetName('TestSingle'),
                        :language('de'),
                    }),
                    status => 200;
        };
        check-mock $fake-store,
                *.called('get-pdf-export', times => 1);
    }
}

subtest 'Store data' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/store_data', {
            test post(json => { :datasetName('DatasetA'), :variable('x'), :value('1'), :row(1) }),
            status => 204,
        };
        check-mock $fake-store,
            *.called('store-data', times => 1);
    }
}

subtest 'Store data (regional)' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/store_data', {
            test post(json => {
                :datasetName('DatasetA'), :variable('x'), :value('1'), :row(1),
                :branches(@('a', 'b')), :options(@('x', 'y'))
             }),
            status => 204,
        };
        check-mock $fake-store,
            *.called('store-data', times => 2);
    }
}

subtest 'Store variable comment' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/store_input_comment', {
            test post(json => { :datasetName('Dataset'), :variable('x'), :comment('bla bla' ) }),
                status => 204,
        };
        check-mock $fake-store,
            *.called('store-input-comment', times => 1);
    }
}

subtest 'Delete instance' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/delete_instance', {
            test post(json => { :datasetName('Dataset'), :variablePattern('x'), :instance('MK') }),
                status => 204,
        };
        check-mock $fake-store,
            *.called('delete-instance', times => 1);
    }
}

subtest 'Load branch data' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/load_branch_data', {
            test post(json => { :name('DatasetC') }),
                status => 200,
                json   => [1, 2 ], # check what we really expect
        };
        check-mock $fake-store,
            *.called('load-branch-data', times => 1);
    }
}

subtest 'Store branch data' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/store_branch_data', {
            test post(json => { :datasetName('DatasetC'), data => %( :x(1), :y(2) ) }),
                status => 200,
                json   => { stored => 1 }, # check what we really expect
        };
        check-mock $fake-store,
            *.called('store-branch-data', times => 1);
    }
}

subtest 'Rename instance' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/rename_instance', {
            test post(json => { :datasetName('TestDataset'), :oldName('InstC'), :newName('InstD'), :variablePattern('xxx') }),
                status => 204,
        };
        check-mock $fake-store,
            *.called('rename-instance', times => 1);
    }
}

subtest 'Order instances' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/order_instances', {
            test post(json => { :datasetName('DatasetA'), instances => ('InstC', 'InstD') }),
                status => 200,
                json   => { sorted => 1 },
        };
        check-mock $fake-store,
            *.called('order-instances', times => 1);
    }
}

done-testing;

=begin pod

=COPYRIGHT Copyright (c) 2020 by OETIKER+PARTNER AG. All rights reserved.

=AUTHOR S<Fritz Zaucker E<lt>fritz.zaucker@oetiker.chE<gt>>

See C<git blame> for other contributors.

Example input variable:

                    :branch("false"),
                    :defaults(${
                        :calc(Any),
                        :gui(Any)
                    }),
                    :enum(${}),
                    :gui(${
                        :de("Tierhaltung::Milchkühe[]"),
                        :en("Livestock::DairyCow[]"),
                        :fr("Production animale::Vâches laitières[]")
                    }),
                    :help(${
                        :de("<p>Vorschlag für Standardwert: 7500 kg pro Jahr</p>"),
                        :en("<p>Standard value for Switzerland: 7500 kg per head and year</p>"),
                        :fr("<p>Proposition de valeur standard: 7500 kg par an </p>")
                    }),
                    :labels(${
                        :de("Durchschnittliche Milchleistung pro Kuh"),
                        :en("Milk yield per dairy cow"),
                        :fr("Production laitière moyenne par vache")
                    }),
                    :models($(
                        "all",
                    )),
                    :options(
                        $[]
                    ),
                    :optionsLang(
                        $[]
                    ),
                    :order(500000),
                    :type("float"),
                    :units(${
                        :de("kg/Jahr"),
                        :en("kg/year"),
                        :fr("kg/an")}),
                    :validator(${
                        :args($["1000", "15000"]),
                        :name("between")
                    })
                    :variable("Livestock::DairyCow[]::Excretion::CMilk::milk_yield")

=end pod
