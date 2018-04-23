use Agrammon::Formula::ControlFlow;

sub get-builtins is export {
    return INIT %(
        writeLog => -> %langMessages {
            with $*AGRAMMON-LOG {
                .add-to-log(%langMessages);
            }
        },
        die => -> *@message {
            die X::Agrammon::Formula::Died.new(message => @message.join || 'Died');
        },
        warn => -> *@message {
            warn @message.join || 'Warning';
        },
        abs => &abs
    )
}
