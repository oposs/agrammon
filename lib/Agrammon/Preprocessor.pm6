use v6;
#| Base of all Agrammon preprocessor exceptions.
role X::Agrammon::Preprocessor is Exception {
    has Int $.line is required;
}

#| Exception thrown when there is an invalid directive.
class X::Agrammon::Preprocessor::InvalidDirective does X::Agrammon::Preprocessor {
    has Str $.directive is required;
    method message() {
        "Invalid preprocessor directive '$!directive.trim-trailing()' at line $!line"
    }
}

#| Exception thrown when there is an unclosed directive.
class X::Agrammon::Preprocessor::UnclosedDirective does X::Agrammon::Preprocessor {
    method message() {
        "Missing ?endif for directive starting at line $!line"
    }
}

#| Exception thrown when there is an unexpected closer of some kind.
class X::Agrammon::Preprocessor::UnexpectedCloser does X::Agrammon::Preprocessor {
    has Str $.unexpected is required;
    method message() {
        "Unexpected $!unexpected when no open preprocessor directives at line $!line"
    }
}

#| Exception thrown when an elsif comes after an else.
class X::Agrammon::Preprocessor::ElsifAfterElse does X::Agrammon::Preprocessor {
    method message() {
        "Invalid preprocessor ?elsif found after ?else at line $!line"
    }
}

#| Preprocess the provided source code for C-style preprocessor directives (but
#| with a different syntax, given `#` is taken as the comment character). The
#| syntax available is:
#|     ?if FOO
#|     foo stuff
#|     ?elsif BAR
#|     bar stuff
#|     ?else
#|     other stuff
#|     ?endif
#| Where the C<elsif> and C<else> parts are optional. The symbols FOO and BAR
#| will be looked up and truth-tested in C<%options>. Nesting is allowed. An
#| error will be raised on mis-nesting.
sub preprocess(Str $source, %options --> Str) is export {
    my @result-lines;
    my class OpenDirective {
        has Int $.start-line is required;       #= Line where section was opened
        has Bool $.enabled is required;         #= If output is enabled
        has Bool $.matched is required;         #= If any branch (if, elsif) matched
        has Bool $.accept-elsif is required;    #= If we'll accept an elsif after this
    }
    my OpenDirective @open;
    for $source.lines.kv -> $number, $content {
        if $content.starts-with('?') {
            @result-lines.push('');
            given $content {
                when /^ '?if' \h+ [$<negate>='!']? <option=.ident> \h* $/ {
                    my $enabled = $<negate> ?? .not !! .so given %options{~$<option>};
                    my $matched = $enabled;
                    my $start-line = $number + 1;
                    @open.push(OpenDirective.new(:$start-line, :$enabled, :$matched, :accept-elsif));
                }
                when /^ '?elsif' \h+ [$<negate>='!']? <option=.ident> \h* $/ {
                    if @open.pop -> $prev-part {
                        unless $prev-part.accept-elsif {
                            die X::Agrammon::Preprocessor::ElsifAfterElse.new: :line($number + 1);
                        }
                        my $enabled = so !$prev-part.matched && ($<negate> ?? .not !! .so given %options{~$<option>});
                        my $matched = $prev-part.matched || $enabled;
                        my $start-line = $number + 1;
                        @open.push(OpenDirective.new(:$start-line, :$enabled, :$matched, :accept-elsif));
                    }
                    else {
                        die X::Agrammon::Preprocessor::UnexpectedCloser.new:
                                :unexpected('?elsif'), :line($number + 1);
                    }
                }
                when /^ '?else' \h* $/ {
                    if @open.pop -> $prev-part {
                        my $enabled = !$prev-part.matched;
                        my $start-line = $number + 1;
                        @open.push(OpenDirective.new(:$start-line, :$enabled, :matched, :!accept-elsif));
                    }
                    else {
                        die X::Agrammon::Preprocessor::UnexpectedCloser.new:
                                :unexpected('?else'), :line($number + 1);
                    }
                }
                when /^ '?endif' \h* $/ {
                    unless @open.pop {
                        die X::Agrammon::Preprocessor::UnexpectedCloser.new:
                            :unexpected('?endif'), :line($number + 1);
                    }
                }
                default {
                    die X::Agrammon::Preprocessor::InvalidDirective.new:
                            :directive($content), :line($number + 1);
                }
            }
        }
        elsif all(@open>>.enabled) {
            @result-lines.push($content);
        }
        else {
            @result-lines.push('');
        }
    }
    if @open.pop -> $oops {
        die X::Agrammon::Preprocessor::UnclosedDirective.new: :line($oops.start-line);
    }
    @result-lines.join("\n") ~ "\n"
}
