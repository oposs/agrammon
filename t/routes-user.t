use v6;
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

my $role = 'user';
my $fake-auth = make-fake-auth($role);
my $fake-store = mocked(Agrammon::Web::Service,
    returning => {
        get-account-key => -> $email, $password {
        },
    },
    overriding => {
        reset-password => -> $user, $email, $password, $key? {
        },
        change-password => -> $user, $old-password, $new-password {
        },
        create-account => -> $user, $email, $password, $firstname, $lastname, $org, $role {
            $email
        },
    }
);

subtest 'Get account key' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/get_account_key', {
            test post(json => { :email('foo@bar.com'), :password('xyz') }),
                status => 204;
        };
        check-mock $fake-store,
            *.called('get-account-key', times => 1);
    }
}

subtest 'Reset password' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/reset_password', {
            test post(json => { :email('foo@bar.ch'), :password('pass'), :key('xyz12345') }),
                status => 204,
        };
        check-mock $fake-store,
            *.called('reset-password', times => 1);
    }
}

subtest 'Change password' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/change_password', {
            test post(json => { :oldPassword('old'),  :newPassword('new') }),
                status => 204,
        };
        check-mock $fake-store,
            *.called('change-password', times => 1);
    }
}

subtest 'Create account' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/create_account', {
            test post(json => { :email('foo@bar.com'), :password('xyz'), :role('user') }),
                status => 200,
                json   => { :username('foo@bar.com') };
            test post(json => { :email('foo2@bar.com'), :password('xyz'), :role('admin') }),
                status => 200,
                json   => { :username('foo2@bar.com') };
            test post(json => { :email('foo3@bar.com'), :password('xyz'), :role('unknown') }),
                status => 400;
        };
        check-mock $fake-store,
            *.called('create-account', times => 2);
    }
}

done-testing;

=begin pod

=COPYRIGHT Copyright (c) 2020 by OETIKER+PARTNER AG. All rights reserved.

=AUTHOR S<Fritz Zaucker E<lt>fritz.zaucker@oetiker.chE<gt>>

See C<git blame> for other contributors.

=end pod
