use v6;

class Agrammon::Formula::LogCollector {
    class Entry {
        has $.taxonomy is required;
        has %.gui is required;
        has $.instance is required;
        has $.output is required;
        has %.messages is required;

        method to-json {
            { :$!taxonomy, :%!gui, :$!output, :%!messages }
        }
    }

    has Entry @.entries;

    method add-to-log(Str $taxonomy, %gui, Str $instance, Str $output, %messages --> Nil) {
        @!entries.push(Entry.new(:$taxonomy, :%gui, :$instance, :$output, :%messages));
    }

    method messages-for-lang($lang) {
        [@!entries.map({ .messages.{$lang} // Empty })]
    }
}
