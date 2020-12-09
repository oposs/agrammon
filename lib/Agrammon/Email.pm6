use v6;
use Net::SMTP::Client::Async;
use MIME::Base64;
use Email::MIME;

class Agrammon::Email {
    has $!msg;
    has $!subject;
    has $!to;
    has $!from;
    has $!attachment;
#    has $!filename;
    has $!mail;

    submethod TWEAK( :$attachment, :$msg, :$filename, :$to, :$from, :$subject --> Nil) {
        $!to = $to;
        $!from = $from;
        $!subject = $subject;
        if $attachment {
            $!attachment = Email::MIME.create(
                attributes => {
                    'content-type' => "application/pdf; name=$filename",
                    'charset' => 'utf-8',
                    'encoding' => 'base64',
                },
                # body-str => MIME::Base64.encode($pdf),
                body => $attachment,
            );
        }
        $!msg = Email::MIME.create(
            attributes => {
                'content-type' => 'text/plain',
                'charset' => 'utf-8',
                'encoding' => 'quoted-printable'
            },
            body-str => $msg,
        );
        $!mail = Email::MIME.create(
            header-str => [
                'to'      => $!to,
                'from'    => $!from,
                'subject' => $!subject
            ],
            parts => [
                $!msg,
                $!attachment,
            ]
        );
    }

    method mail {
        $!mail
    }

    method send {
        with await Net::SMTP::Client::Async.connect(:host<mail.oetiker.ch>, :port(25), :!secure) {
            await .hello;

            await .send-message(
                :$!from,
                :to([ $!to ]),
                :message(~$!mail),
            );

            .quit;

            CATCH {
                when X::Net::SMTP::Client::Async {
                    note "Unable to send email message: $_";
                    .quit
                }
            }
        }
    }

}
