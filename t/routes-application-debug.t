use v6;

use Agrammon::Web::Routes;
use Agrammon::Web::Service;
use Agrammon::Web::SessionUser;
use Spreadsheet::XLSX;

use Cro::HTTP::Test;
use Test::Mock;
use Test;

# plan 14;

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
        get-excel-export => -> $user, %params {
#            diag %params;
            Spreadsheet::XLSX.new;
        },
        get-pdf-export => -> $user, %params {
#            diag %params;
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


subtest 'Get PDF report without newline' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/export/pdf', {
            test post(
                    content-type => 'application/x-www-form-urlencoded',
                    body => {
                        :datasetName('TestSingle'),
                        :language('de'),
                        :type('submission'),
                        :senderName("Fritz ZauckerXXX4600 Olten"),
                        :farmNumber(42),
                        :farmSituation('Before'),
                        :recipientName('lawa'),
                        :recipientEmail('fritz@zaucker.ch'),
                        :comment('No comment'),
                    }),
                    status => 200;
        };
        check-mock $fake-store,
                *.called('get-pdf-export', times => 1);
    }
}

subtest 'Get PDF report with newline' => {
    test-service routes($fake-store), :$fake-auth, {
        test-given '/export/pdf', {
            test post(
                    content-type => 'application/x-www-form-urlencoded',
                    body => {
                        :datasetName('TestSingle'),
                        :language('de'),
                        :type('submission'),
                        :senderName("Fritz Zaucker\n4600 Olten"),
                        :farmNumber(42),
                        :farmSituation('Before'),
                        :recipientName('lawa'),
                        :recipientEmail('fritz@zaucker.ch'),
                        :comment('No comment'),
                    }),
                    status => 500;
        };
        check-mock $fake-store,
                *.called('get-pdf-export', times => 1);
    }
}

done-testing;
