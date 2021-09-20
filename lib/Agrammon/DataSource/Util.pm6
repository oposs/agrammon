use v6;

sub maybe-numify($value) is export {
    return $value if not $value.defined;
    +$value // $value
}
