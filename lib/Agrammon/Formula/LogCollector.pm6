use v6;

class Agrammon::Formula::LogCollector {
    class Entry {
        has $.taxonomy is required;
        has $.output is required;
        has %.messages is required;

        method to-json {
            { :$!taxonomy, :$!output, :%!messages }
        }
    }

    has Entry @.entries;

    method add-to-log(Str $taxonomy, Str $output, %messages --> Nil) {
        @!entries.push(Entry.new(:$taxonomy, :$output, :%messages));
    }

    method messages-for-lang($lang) {
        [@!entries.map({ .messages.{$lang} // Empty })]
    }
}
