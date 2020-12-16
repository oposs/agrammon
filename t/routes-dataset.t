use v6;
use Agrammon::Web::Routes;
use Agrammon::Web::Service;
use Agrammon::Web::SessionUser;

use Cro::HTTP::Test;
use Test::Mock;
use Test;

plan 15;

# routing tests related to datasets

sub make-fake-auth($role) {
    mocked(
        Agrammon::Web::SessionUser,
        returning => { :id(42), :logged-in, }
    )
}

my $fake-user = %( :id(1), :username('foor@bar.ch'), );

my $fake-tag-a = %( :id(42), :name('TagA'), :user($fake-user));
my $fake-tag-b = %( :id(43), :name('TagB'), :user($fake-user));

my $fake-dataset-a = %( :id(42), :name('DatasetA'), :user($fake-user));
my $fake-dataset-b = %( :id(43), :name('DatasetB'), :user($fake-user));


my $role = 'user';
my $fake-auth = make-fake-auth($role);
my $fake-store = mocked(Agrammon::Web::Service,
    returning => {
        cfg          => Agrammon::Config.new(gui => :variant('Single'), model => :variant('SHL')),
        get-datasets => ($fake-dataset-a, $fake-dataset-b),
        get-tags     => ($fake-tag-a, $fake-tag-b),
        load-dataset => ( 1, 2 ),
        store-dataset-comment => 1,
    },
    overriding => {
        create-tag => -> $user, $name {
        },
        rename-tag => -> $user, $old, $new {
        },
        delete-tag => -> $user, $name {
        },
        set-tag => -> $user, @datasets, $name {
        },
        remove-tag => -> $user, @datasets, $name {
        },
        create-dataset => -> $user, $name {
            $name
        },
        rename-dataset => -> $user, $old, $new {
        },
        clone-dataset => -> $user,
                            Str $new-username,
                            Str $old-dataset, Str $new-dataset {
        },
        submit-dataset => -> $user, %params {
            %( name => %params<name> )
        },
        delete-datasets => -> $user, @datasets {
            @datasets.elems;
        },
        send-datasets => -> $user, @datasets, $recipient {
            %( sent => @datasets.elems );
        }
    }
);

subtest 'Create tag' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/create_tag', {
            test post(json => { :name('TagA') }),
                status => 204,
        };
        check-mock $fake-store,
            *.called('create-tag',  times => 1  );
    }
}

subtest 'Rename tag' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/rename_tag', {
            test post(json => { :oldName('TagC'),  :newName('TagD')}),
                status => 204,
        };
        check-mock $fake-store,
            *.called('rename-tag', times => 1);
    }
}

subtest 'Delete tag' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/delete_tag', {
            test post(json => { :name('TagC') }),
                status => 204,
        };
        check-mock $fake-store,
            *.called('delete-tag', times => 1);
    }
}

subtest 'Set tag' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/set_tag', {
            test post(json => { datasets => ('DatasetA', 'DatasetB'), :tagName('TagC') }),
                status => 204,
        };
        check-mock $fake-store,
            *.called('set-tag', times => 1);
    }
}

subtest 'Remove tag' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/remove_tag', {
            test post(json => { datasets => ('DatasetA', 'DatasetB'), :tagName('TagC') }),
                status => 204,
        };
        check-mock $fake-store,
            *.called('remove-tag', times => 1);
    }
}

subtest 'Get all tags' => {
    test-service routes($fake-store), :$fake-auth, {
        test post('/get_tags'),
                status => 200,
                json   => [
                    {
                        id => 42,
                        name => 'TagA',
                        user => { id => 1, username => 'foor@bar.ch' },
                    },
                    {
                        id => 43,
                        name => 'TagB',
                        user => { id => 1, username => 'foor@bar.ch' },
                    }
                ];

        check-mock $fake-store,
            *.called('get-tags', times => 1);
    }
}

subtest 'Create dataset' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/create_dataset', {
            test post(json => { :name('DatasetC') }),
                status => 200,
                json   => { name => 'DatasetC' },
        };
        check-mock $fake-store,
            *.called('create-dataset', times => 1);
    }
}

subtest 'Load dataset' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/load_dataset', {
            test post(json => { :name('DatasetC') }),
                status => 200,
                json   => [1, 2 ], # check what we really expect
        };
        check-mock $fake-store,
            *.called('load-dataset', times => 1);
    }
}

subtest 'Clone dataset' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/clone_dataset', {
            test post(json => { :newUsername('foo'), :oldDataset('DatasetC'),  :newDataset('DatasetD') }),
                status => 204,
        };
        check-mock $fake-store,
            *.called('clone-dataset', times => 1);
    }
}

subtest 'Rename dataset' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/rename_dataset', {
            test post(json => { :oldName('DatasetC'),  :newName('DatasetD') }),
                status => 204,
        };
        check-mock $fake-store,
            *.called('rename-dataset', times => 1);
    }
}

subtest 'Submit dataset' => {
    my %params = :name('DatasetC'), :mail('foo@bar.ch');
    test-service routes($fake-store), :$fake-auth, {
        test-given '/submit_dataset', {
            test post( json => %params ),
                status => 200,
                json   => { name => 'DatasetC' },
        };
        check-mock $fake-store,
            *.called('submit-dataset', times => 1);
    }
}

subtest 'Store dataset comment' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/store_dataset_comment', {
            test post(json => { :dataset('DatasetC'), :comment('bla bla')}),
                status => 200,
                json   => { :stored(1) },
        };
        check-mock $fake-store,
            *.called('store-dataset-comment', times => 1);
    }
}

subtest 'Get all datasets' => {
    test-service routes($fake-store), :$fake-auth, {
        test post('/get_datasets'),
                status => 200,
                json   => [
                    {
                        id => 42,
                        name => 'DatasetA',
                        user => { id => 1, username => 'foor@bar.ch' },
                    },
                    {
                        id => 43,
                        name => 'DatasetB',
                        user =>  { id => 1, username => 'foor@bar.ch' },
                    }
                ];

        check-mock $fake-store,
            *.called('cfg', times => 1),
            *.called('get-datasets', times => 1);
    }
}

subtest 'Send datasets' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/send_datasets', {
            test post(json => { datasets => ( 'DatasetC', 'DatasetD' ), :recipient('fritz@zaucker.ch') },  ),
                status => 200,
                json   => { :sent(['DatasetC', 'DatasetD',]) },
        };
        check-mock $fake-store,
            *.called('send-datasets', times => 1);
    }
}

subtest 'Delete datasets' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/delete_datasets', {
            test post(json => { datasets => ( 'DatasetC', 'DatasetD' ) } ),
                status => 200,
                json   => { :deleted(2) },
        };
        check-mock $fake-store,
            *.called('delete-datasets', times => 1);
    }
}


done-testing;

=begin pod

=COPYRIGHT Copyright (c) 2020 by OETIKER+PARTNER AG. All rights reserved.

=AUTHOR S<Fritz Zaucker E<lt>fritz.zaucker@oetiker.chE<gt>>

See C<git blame> for other contributors.

=end pod
