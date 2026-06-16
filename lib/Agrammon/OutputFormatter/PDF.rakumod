use v6;
use Agrammon::Config;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::OutputFormatter::CollectData;
use Agrammon::Outputs::FilterGroupCollection;
use Agrammon::Timestamp;
use Agrammon::Web::SessionUser;
use Cro::WebApp::Template;

# =============================================================================
# Typst-based PDF formatter. Replaced the earlier lualatex pipeline.
# Required config (General section):
#   typst        — path to the typst binary
#   pdfTimeout   — seconds before the typst (and gs) processes are killed
# Optional:
#   ghostscript  — path to gs; when set, the output PDF gets re-compressed
#                  in place (~5× smaller, comparable to the old lualatex size)
# =============================================================================

class X::Agrammon::OutputFormatter::PDF::Failed is Exception {
    has $.exit-code;
    method message() {
        "PDF generation failed, exit code $!exit-code!";
    }
}

class X::Agrammon::OutputFormatter::PDF::Killed is Exception {
    has $.reason;
    method message() {
        "PDF generation killed, reason $!reason!";
    }
}

sub create-pdf-source($template, %data) is export {
    template-location $*PROGRAM.parent.add('../share/templates');
    render-template($template ~ ".crotmp", %data);
}

sub create-pdf($temp-dir-name, $pdf-prog, $timeout, $username, $dataset-name, %data, :$gs-prog) is export {
    # setup temp dir and files
    my $temp-dir = $*TMPDIR.add($temp-dir-name);
    if not  $temp-dir.e {
        $temp-dir.mkdir;
        note "Created temp-dir $temp-dir";
    }

    my $filename = "agrammon_export_" ~ $username ~ "_$dataset-name";
    # sanitize internally used filename
    $filename ~~ s:g/<-[\w\s_-]>/-/;
    my $source-file = "$temp-dir/$filename.typ".IO;
    my $pdf-file    = "$temp-dir/$filename.pdf".IO;

    # create typst source from template
    $source-file.spurt(create-pdf-source('pdfexport', %data));

    # invoke typst:  typst compile --root <dir> source.typ output.pdf
    # --root restricts file access (defaults to source dir; pin to temp-dir
    # so the typst engine can't traverse out of $temp-dir if the template
    # were ever to `read()` a path).
    my $exit-code;
    my $signal;
    my $reason = 'Unknown';

    my $proc = Proc::Async.new: $pdf-prog,
            'compile',
            '--root', "$temp-dir",
            "$source-file",
            "$pdf-file";

    my $stderr-buf = '';
    react {
        whenever $proc.stdout.lines {
        }
        whenever $proc.stderr.lines {
            $stderr-buf ~= $_ ~ "\n";
        }
        whenever $proc.start {
            $exit-code = .exitcode;
            $signal    = .signal;
            done;
        }
        whenever Promise.in($timeout) {
            $reason = 'Timeout';
            note ‘Timeout. Asking the process to stop’;
            $proc.kill;
            whenever Promise.in(2) {
                note ‘Timeout. Forcing the process to stop’;
                $proc.kill: SIGKILL
            }
        }
    }

    if $exit-code {
        note "$pdf-prog failed for $source-file, exit-code=$exit-code";
        note "$pdf-prog stderr:\n$stderr-buf" if $stderr-buf.chars;
        die X::Agrammon::OutputFormatter::PDF::Failed.new: :$exit-code;
    }
    if $signal {
        note "$pdf-prog killed for $source-file, signal=$signal, reason=$reason";
        die X::Agrammon::OutputFormatter::PDF::Killed.new: :$reason;
    }

    # Optional ghostscript compression. Typst's default PDF output is ~5×
    # the size of an equivalent lualatex PDF because typst's stream
    # compression is conservative. A `gs -dPDFSETTINGS=/printer` pass
    # losslessly re-compresses streams down to lualatex parity (~40 KB vs
    # ~200 KB for a typical dataset) without touching the page layout.
    # Skipped if config doesn't specify `General.ghostscript:`.
    if $gs-prog {
        my $cmp-file = "$temp-dir/$filename.cmp.pdf".IO;
        my $gs-exit;
        my $gs-proc = Proc::Async.new: $gs-prog,
                '-sDEVICE=pdfwrite', '-dCompatibilityLevel=1.7',
                '-dPDFSETTINGS=/printer', '-dNOPAUSE', '-dBATCH', '-dQUIET',
                "-sOutputFile=$cmp-file", "$pdf-file";
        react {
            whenever $gs-proc.stdout.lines {}
            whenever $gs-proc.stderr {}
            whenever $gs-proc.start {
                $gs-exit = .exitcode;
                done;
            }
            whenever Promise.in($timeout) {
                note "Ghostscript timeout; falling back to uncompressed PDF";
                $gs-proc.kill;
                done;
            }
        }
        if $gs-exit == 0 && $cmp-file.e && $cmp-file.s > 0 {
            # replace original with compressed
            $pdf-file.unlink;
            $cmp-file.rename($pdf-file);
        }
        else {
            note "Ghostscript compression failed (exit=$gs-exit); using uncompressed PDF";
            $cmp-file.unlink if $cmp-file.e;
        }
    }

    # read content of PDF file created
    my $pdf = $pdf-file.slurp(:bin);
    # cleanup if successful, otherwise kept for debugging.
    unlink $source-file, $pdf-file unless %*ENV<AGRAMMON_KEEP_FILES>;

    return $pdf;
}

# Typst-specific text escapes. Typst markup mode treats these as syntactic:
#   *  _  `  #  @  $  [  ]  \  ~
# All get backslash-escaped. The legacy Agrammon convention `__` (double
# underscore as 2em indentation marker) is preserved by post-processing the
# escaped form `\_\_` into a typst horizontal-space call `#h(2em)`.
sub typst-escape(Str $in) is export {
    my $out = $in // '';
    # escape every typst-special char in markup mode
    $out ~~ s:g/(<[\\*_`#@$~\[\]]>)/\\$0/;
    # Agrammon convention: __ → 2em indent (LaTeX equivalent was \hspace{2em})
    $out ~~ s:g/'\\_\\_'/#h(2em)/;
    return $out;
}

# Chemistry formulas — render with typst math mode (subscripts).
# These are applied AFTER typst-escape so the `$` typst-math delimiters
# inserted here are not themselves escaped.
sub typst-chemify(Str $in) is export {
    my $out = $in // '';
    # `s:g[pattern] = literal` avoids `$` sigil-confusion in the
    # typst math-mode replacement strings.
    $out ~~ s:g[NOx]  = '$ "NO"_x $';
    $out ~~ s:g[NH3]  = '$ "NH"_3 $';
    $out ~~ s:g[N2O]  = '$ "N"_2 "O" $';
    $out ~~ s:g[NO2]  = '$ "NO"_2 $';
    $out ~~ s:g[N2]   = '$ "N"_2 $';
    return $out;
}

# Tight inter-word spacing for unit strings ("kg N year-1" → kg\,N\,year-1).
# Typst equivalent uses `#h(0.3em)` which renders inline in markup mode.
sub typst-small-spaces(Str $in) is export {
    my $out = $in // '';
    $out ~~ s:g/\s+/#h(0.3em)/;
    return $out;
}

multi format-value(Rat $value) {
    sprintf '%.2f', $value;
}

multi format-value(Numeric $value) {
    sprintf '%.2f', $value;
}

multi format-value(IntStr $value) {
    return $value;
}

multi format-value(Str $value) {
    typst-escape($value);
}

multi format-value(Any) {
    return "UNDEFINED VALUE";
}

sub input-output-as-pdf(
    Agrammon::Config $cfg,
    Agrammon::Web::SessionUser $user,
    Str $dataset-name, Agrammon::Model $model,
    Agrammon::Outputs $outputs, Agrammon::Inputs $inputs, $reports,
    Str $language, Int $report-selected,
    Bool $include-filters, Bool $all-filters,
    :%submission
) is export {

    my %data = collect-data(
        $model,
        $outputs, $inputs, $reports,
        $language, $report-selected,
        $include-filters, $all-filters,
    );

    my @log;
    %data<log> = @log;
    my @entries := $outputs.log-collector.entries;
    for @entries -> $_ {
        @log.push(%(
            message  => typst-escape(.messages{$language}),
            gui      => .gui{$language},
            instance => typst-escape(.instance),
        ));
    }

    my %lx = $cfg.translations{$language};

    my %titles = %(
        report => %lx{'title report'},
        data => %(
            section => %lx{'data section'},
            user    => %lx{'data user'},
            dataset => %lx{'data dataset'},
        ),
        outputs   => %lx{'outputs'},
        outputLog => %lx{'outputLog'},
        inputs    => %lx{'inputs'},
    );

    if %submission {
        my $info = sprintf %lx{'submission info'}, %submission<recipient-name>, %submission<dataset-name>;
        %titles<submission> = %(
            farm => %lx{'submission farm'},
            situation => %lx{'submission farm'},
            sender => %lx{'submission sender'},
            recipient => %lx{'submission recipient'},
            comment => %lx{'submission comment'},
            :$info,
        );
    }

    my %print-labels = %data<print-labels>;

    my @output-formatted;
    my $last-print = '';
    my $first = True;
    for %data<outputs> -> @outputs {
        for @outputs.sort(+*.<order>) -> %rec {
            my $print = %rec<print>;
            if $print and $print ne $last-print {
                @output-formatted.push(%(
                    :section(%print-labels{$print}{$language} // 'NO-TITLE'),
                    :$first));
                $first = False if $first;
                $last-print = $print;
            }
            @output-formatted.push(%(
                :unit(typst-small-spaces(typst-escape(%rec<unit> // ''))),
                :label(typst-chemify(typst-escape(%rec<label> // ''))),
                :value(format-value(%rec<value>)),
            ));
        }
    }

    my @input-formatted;
    my @inputs := %data<inputs>;
    $last-print = '';
    my $last-instance = '';
    my $last-module = '';
    my $first-module = True;
    my $first-instance = True;
    for @inputs -> %rec {
        my $new-module = False;
        my $new-instance = False;

        my $module-translated = %rec<gui-translated>;
        my $module = %rec<gui>;
        my $module-title = $module-translated // $module;

        if $module ne $last-module {
            @input-formatted.push( %(
                :module(typst-escape($module-title.subst(/ '::' /, ' '))),
                :$first-module));
            $last-module = $module;
            $new-module = True;
            $first-module = False;
            $first-instance = True;
        }

        my $instance = %rec<instance>;
        if $instance and $instance ne $last-instance {
            @input-formatted.push( %(
                :instance(typst-escape($instance)),
                :$first-instance));
            $last-instance = $instance;
            $new-instance = True;
            $first-instance = False;
        }

        my $first-line = $new-module && ! $new-instance;

        @input-formatted.push(%(
            :unit(typst-small-spaces(typst-escape(%rec<unit>))),
            :label(typst-chemify(typst-escape(%rec<input-translated> // %rec<input>))),
            :value(format-value(%rec<value-translated>)),
            :comment(typst-escape(%rec<comment> // '')),
            :$first-line));
    }

    # setup template data
    %data<titles>     = %titles;
    %data<dataset>    = typst-escape($dataset-name   // 'NO DATASET');
    %data<username>   = typst-escape($user.username) // 'NO USER';
    %data<model>      = $cfg.gui-variant // 'NO MODEL';
    %data<timestamp>  = timestamp;
    %data<version>    = typst-escape($cfg.gui-title{$language} // 'NO  VERSION');
    %data<outputs>    = @output-formatted;
    %data<inputs>     = @input-formatted;
    %data<submission> = %submission;

    # Config:
    #   typst        — path to the typst binary (required).
    #   pdfTimeout   — seconds before the typst (and gs) processes are killed.
    #   ghostscript  — optional; when set, the output PDF gets re-compressed
    #                  in place (~5× smaller). Skipped if absent.
    my $pdf-prog = $cfg.general<typst>;
    my $timeout  = $cfg.general<pdfTimeout> // 30;
    my $gs-prog  = $cfg.general<ghostscript>;

    return create-pdf(
        $*TMPDIR.add($cfg.general<tmpDir>),
        $pdf-prog,
        $timeout,
        $user.username,
        $dataset-name,
        %data,
        :$gs-prog,
    );
}
