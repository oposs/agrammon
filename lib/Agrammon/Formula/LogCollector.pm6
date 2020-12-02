use v6;

class Agrammon::Formula::LogCollector {
    has @.messages;

    method add-to-log(%lang-messages --> Nil) {
        @!messages.push(%lang-messages);
    }

    method messages-for-lang($lang) {
        [@!messages.map({ .{$lang} // Empty })]
    }
}
