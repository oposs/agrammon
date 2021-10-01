use v6;

sub maybe-numify($value) is export {
    .return without $value;
    +$value // $value
}
