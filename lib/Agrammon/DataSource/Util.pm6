use v6;

sub maybe-numify($value) is export {
    +$value // $value
}
