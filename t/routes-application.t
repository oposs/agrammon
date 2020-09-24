use Agrammon::Web::Routes;
use Agrammon::Web::Service;
use Agrammon::Web::SessionUser;

use Cro::HTTP::Test;
use Test::Mock;
use Test;

plan 11;

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
            test post(json => { :dataset_name('DatasetA'), :data_var('x'), :data_val('1'), :data_row(1) }),
            status => 200,
            json   => { ret => 1 }
        };
        check-mock $fake-store,
            *.called('store-data', times => 1);
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

=end pod
