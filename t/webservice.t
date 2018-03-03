use v6;
use Agrammon::Webservice;
use Test;
plan 6;

todo "Not implemented yet", 6;
subtest "GUI config" => {
    my $ws = Agrammon::Webservice.new();
    is $ws.get-cfg(), 'test';
}

subtest "Authentication" => {
    flunk("Not implemented");
}

subtest "Datasets" => {
    flunk("Not implemented");
}

subtest "Model loading" => {
    flunk("Not implemented");
}

subtest "Input loading" => {
    flunk("Not implemented");
}

subtest "Output loading" => {
    flunk("Not implemented");
}

done-testing;
