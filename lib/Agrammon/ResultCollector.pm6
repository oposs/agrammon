use v6;
use OO::Monitors;

monitor Agrammon::ResultCollector {
    has %.results;
    has %.validation-errors;

    method add-validation-errors($simulation-name, $dataset-id, @errors --> Nil) {
        %!validation-errors{$simulation-name}{$dataset-id} = @errors;
    }
    method add-result($simulation-name, $dataset-id, $result --> Nil) {
        %!results{$simulation-name}{$dataset-id} = $result;
    }
}
