use v6;
use OO::Monitors;

monitor Agrammon::ResultCollector {
    has %.results;

    method add-result($simulation-name, $dataset-id, $result --> Nil) {
        %!results{$simulation-name}{$dataset-id} = $result;
    }
}
