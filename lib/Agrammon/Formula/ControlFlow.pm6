class X::Agrammon::Formula::ReturnException is Exception {
    has $.payload is default(Nil);
}

class X::Agrammon::Formula::SucceedException is Exception {
    has $.payload is default(Nil);
}

class X::Agrammon::Formula::Died is Exception {
    has $.message;
}
