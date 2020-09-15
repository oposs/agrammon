use Agrammon::Web::Routes;
use Agrammon::Web::Service;
use Agrammon::Web::SessionUser;

use Cro::HTTP::Test;
use Test::Mock;
use Test;

# routing tests related to user accounts

sub make-fake-auth($role) {
    mocked(
        Agrammon::Web::SessionUser,
        returning => { :id(42), :logged-in, }
    )
}

# my $fake-user = %( :id(1), :username('foor@bar.ch'), );

# my $fake-tag-a = %( :id(42), :name('TagA'), :user($fake-user));
# my $fake-tag-b = %( :id(43), :name('TagB'), :user($fake-user));

# my $fake-dataset-a = %( :id(42), :name('DatasetA'), :user($fake-user));
# my $fake-dataset-b = %( :id(43), :name('DatasetB'), :user($fake-user));


my $role = 'user';
my $fake-auth = make-fake-auth($role);
my $fake-store = mocked(Agrammon::Web::Service,
    returning => {
    },
    overriding => {
        reset-password => -> $email, $password, $key {
            %( reset => 1 )
        },
        change-password => -> $old-password, $new-password {
            %( changed => 1 )
        },
        create-account => -> $user, %data {
            %( created => 1 )
        },
    }
);

subtest 'Reset password' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/reset_password', {
            test post(json => { :email('foo@bar.ch'), :password('pass'), :key('xyz12345') }),
                status => 200,
                json   => { reset => 1 },
        };
        check-mock $fake-store,
            *.called('reset-password', times => 1);
    }
}

subtest 'Change password' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/change_password', {
            test post(json => { :old-password('old'),  :new-password('new') }),
                status => 200,
                json   => { changed => 1 },
        };
        check-mock $fake-store,
            *.called('change-password', times => 1);
    }
}

subtest 'Create account' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/create_account', {
            test post(json => { :email('foo@bar.ch') }),
                status => 200,
                json   => { created => 1 },
        };
        check-mock $fake-store,
            *.called('create-account', times => 1);
    }
}

done-testing;

=begin pod

=COPYRIGHT Copyright (c) 2020 by OETIKER+PARTNER AG. All rights reserved.

=AUTHOR S<Fritz WorthZauckerington E<lt>fritz.zaucker@oetiker.chE<gt>>

See C<git blame> for other contributors.

=end pod
