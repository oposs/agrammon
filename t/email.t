use v6;
use Agrammon::Email;
use Email::MIME;
use MIME::Base64;
use Test;

# plan 8;

my $pdf = 't/test-data/agrammon_export.pdf'.IO.slurp :bin;
my $attachment = Email::MIME.create(
        attributes => {
            'content-type' => 'application/pdf; name=agrammon_export.pdf',
            'charset'      => 'utf-8',
            'encoding'     => 'base64'
        },
#        body-str => MIME::Base64.encode($pdf),
        body => $pdf,
);

my $plain = Email::MIME.create(
        attributes => {
            'content-type' => 'text/plain',
            'charset' => 'utf-8',
            'encoding' => 'quoted-printable'
        },
        body-str => 'Hello«Fritz',
);


my $eml = Email::MIME.create(
        header-str => [
            'from' => 'zaucker@oetiker.ch',
            'subject' => 'This is a»test.'
        ],
        parts => [
            $plain,
            $attachment,
        ]
);

ok $eml ~~ Email::MIME, 'Can create a simple email.';
#dd $eml.parts;
#dd $eml.parts[0].body-str;
#dd MIME::Base64.decode($eml.parts[1].body-str);
# 'test.pdf'.IO.spurt(MIME::Base64.decode($eml.parts[1].body-str), :bin);

my $email = Agrammon::Email.new(
    :to('fritz@zaucker.ch'),
    :from('support@agrammon.ch'),
    :subject('Mail from Agrammon'),
    :msg('Hello world'),
    :attachment($pdf),
    :filename('agrammon_export.pdf')
);
ok $email ~~ Agrammon::Email, 'Can create Agrammon Mail';
ok $email.mail ~~ Email::MIME, 'Email is Email::MIME';
# dd $email.mail.header-pairs;
for $email.mail.header-pairs -> $header {
    given $header[0] {
        when 'to' { is $header[1], 'fritz@zaucker.ch', "Correct recipient"; }
        when 'from' { is $header[1], 'support@agrammon.ch', "Correct sender"; }
        when 'subject' { is $header[1], 'Mail from Agrammon', "Correct subject"; }
        when 'msg' { is $header[1], 'Hello world', "Correct msg"; }
    }
}
#is $email.from, 'support@agrammon.ch', "Correct sender";
#is $email.subject, 'Mail from Agrammon', "Correct subject";
#is $email.body, 'Hello world', "Correct body";
#ok $email.attachment ~~ Email::MIME, "Has MIME attachment";
$email.send;

done-testing; exit;
is $eml.header-str('subject'), 'This is a»test.', 'Got subject back correctly.';
ok $eml.header('subject') ne $eml.header-str('subject'), 'raw subject is different';
is $eml.body-str, 'Hello«Fritz', 'Got body-str back correctly.';
ok $eml.body-raw ne $eml.body-str, 'raw body is different';


#ok $eml.filename-set('File agrammon_export.pdf'), 'Set the filename';
#is $eml.header('Content-Disposition'), 'attachment; filename="agrammon_export.pdf"', 'Disposition is set';


done-testing;
