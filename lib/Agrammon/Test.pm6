
## THIS FILE TO BE REMOVED AS SOON AS Cro::HTTP::Test supplies these

# Export custom test subs for better readability

use Agrammon::HTTP::Test;

sub is-ok(|c) is hidden-from-backtrace is export {
    test |c, status => 200
}
sub is-no-content(|c) is hidden-from-backtrace is export {
    test |c, status => 204
}
sub is-bad-request(|c) is hidden-from-backtrace is export {
    test |c, status => 400
}
sub is-unauthorized(|c) is hidden-from-backtrace is export {
    test |c, status => 401
}
sub is-forbidden(|c) is hidden-from-backtrace is export {
    test |c, status => 403
}
sub is-not-found(|c) is hidden-from-backtrace is export {
    test |c, status => 404
}
sub is-conflict(|c) is hidden-from-backtrace is export {
    test |c, status => 409
}
sub is-unprocessable-entity(|c) is hidden-from-backtrace is export {
    test |c, status => 422
}

=begin pod

=NAME Easii::HTTP::Test

=COPYRIGHT Copyright (c) 2018, 2019 by OETIKER+PARTNER AG. All rights reserved.

=AUTHOR S<Jonathan Worthington E<lt>jonathan@oetiker.chE<gt>>

See C<git blame> for other contributors.

=end pod
