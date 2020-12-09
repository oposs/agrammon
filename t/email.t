use v6;
use Agrammon::Email;
use Email::MIME;
use Test;

my $pdf = 't/test-data/test.pdf'.IO.slurp :bin;

ok my $email = Agrammon::Email.new(
    :to('fritz@zaucker.ch'),
    :from('support@agrammon.ch'),
    :subject('Mail from Agrammon'),
    :msg('Hello world'),
    :attachment($pdf),
#    :filename('test.pdf')
), "Email created";
ok $email ~~ Agrammon::Email, 'Email is Agrammon::Mail';
ok $email.mail ~~ Email::MIME, 'Email is Email::MIME';
for $email.mail.header-pairs -> $header {
    given $header[0] {
        when 'to' { is $header[1], 'fritz@zaucker.ch', "Correct recipient"; }
        when 'from' { is $header[1], 'support@agrammon.ch', "Correct sender"; }
        when 'subject' { is $header[1], 'Mail from Agrammon', "Correct subject"; }
        when 'msg' { is $header[1], 'Hello world', "Correct msg"; }
    }
}

lives-ok { $email.send }, "Can send eMail" if %*ENV<AGRAMMON_TEST_SEND_MAIL>;

done-testing;
