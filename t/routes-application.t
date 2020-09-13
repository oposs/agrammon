use Agrammon::Web::Routes;
use Agrammon::Web::Service;
use Agrammon::Web::SessionUser;

use Cro::HTTP::Test;
use Test::Mock;
use Test;

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
        get-input-variables  =>  %( :x(1), :y(2) ),
        get-output-variables =>  %( :x(1), :y(2) ),
        store-data => 1,
        load-branch-data => ( 1, 2 )
    },
    overriding => {
        store-variable-comment => -> $user, $name, $comment {
            %( name => $name)
        },
        delete-data => -> $user, $name {
            %( name => $name)
        },
        rename-instance => -> $user, $old, $new {
            %( name => $new)
        },
        order-instances => -> $user, @instances, $dataset-name {
            %( sorted => 1 )
        },
        store-branch-data => -> $user, %data, $dataset-name {
            %( stored => 1 )
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
            test post(json => { :name('DatasetA') } ),
                status => 200,
                json   => { dataset => 'DatasetA', x => 1, y => 2 }
        };
        check-mock $fake-store,
            *.called('get-input-variables', times => 1);
    }
}

subtest 'Get output variables' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/get_output_variables', {
            test post(json => { :data('DatasetA') } ),
            status => 200,
            json   => { x => 1, y => 2 }
        };
        check-mock $fake-store,
            *.called('get-output-variables', times => 1);
    }
}

subtest 'Store data' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/store_data', {
            test post(json => { :dataset_name('DatasetA'), :data_var('x'), :data_val('1'), :data_row(1) } ),
            status => 200,
            json   => { ret => 1 }
        };
        check-mock $fake-store,
            *.called('store-data', times => 1);
    }
}

subtest 'Store variable comment' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/store_variable_comment', {
            test post(json => { :name('x'), :comment('bla bla')}),
                status => 200,
                json   => { name => 'x' },
        };
        check-mock $fake-store,
            *.called('store-variable-comment', times => 1);
    }
}

subtest 'Delete data' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/delete_data', {
            test post(json => { :name('x') }),
                status => 200,
                json   => { name => 'x' },
        };
        check-mock $fake-store,
            *.called('delete-data', times => 1);
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
<<<<<<< HEAD
            test post(json => { data => %( :x(1), :y(2) ), :dataset-name('DatasetC') }),
=======
            test post(json => { data => %( :x(1), :y(2) ), :datasetName('DatasetC') }),
>>>>>>> Add route tests and reorganize routes
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
            test post(json => { :old('InstC'),  :new('InstD')}),
                status => 200,
                json   => { name => 'InstD' },
        };
        check-mock $fake-store,
            *.called('rename-instance', times => 1);
    }
}

subtest 'Order instances' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/order_instances', {
<<<<<<< HEAD
            test post(json => { instances => ('InstC', 'InstD'),  :dataset-name('DatasetA')}),
=======
            test post(json => { instances => ('InstC', 'InstD'),  :datasetName('DatasetA')}),
>>>>>>> Add route tests and reorganize routes
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

<<<<<<< HEAD
=AUTHOR S<Fritz Zaucker E<lt>fritz.zaucker@oetiker.chE<gt>>
=======
=AUTHOR S<Fritz WorthZauckerington E<lt>fritz.zaucker@oetiker.chE<gt>>
>>>>>>> Add route tests and reorganize routes

See C<git blame> for other contributors.

=end pod
