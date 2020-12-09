use v6;
use Agrammon::Config;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::OutputFormatter::CollectData;
use Agrammon::Outputs::FilterGroupCollection;
use Agrammon::Web::SessionUser;
use Cro::WebApp::Template;

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

sub create-latex($template, %data) is export {
    template-location $*PROGRAM.parent.add('../share/templates');
    render-template($template ~ ".crotmp", %data);
}

sub create-pdf($temp-dir, $pdf-prog, $username, $dataset-name, %data) is export {
    my $filename = "agrammon_export_" ~ $username ~ "_$dataset-name";
    my $source-file = "$temp-dir/$filename.tex".IO;
    my $pdf-file    = "$temp-dir/$filename.pdf".IO;
    my $aux-file    = "$temp-dir/$filename.aux".IO;
    my $log-file    = "$temp-dir/$filename.log".IO;

    # create if necessary
    $temp-dir.IO.mkdir;

    # create LaTeX source with template
    $source-file.spurt(create-latex('pdfexport', %data));

    # create PDF, discard STDOUT and STDERR (see .log file if necessary)
    my $exit-code;
    my $signal;
    my $reason = 'Unknown';

    my $proc = Proc::Async.new: :w, $pdf-prog, "--output-directory=$temp-dir", '--safer', '--no-shell-escape', '--', $source-file, ‘-’;
    react {
        # just ignore them
        whenever $proc.stdout.lines {
        }
        whenever $proc.stderr {
        }
        whenever $proc.start {
            $exit-code = .exitcode;
            $signal    = .signal;
            done # gracefully jump from the react block
        }
        whenever Promise.in(5) {
            $reason = 'Timeout';
            note ‘Timeout. Asking the process to stop’;
            $proc.kill; # sends SIGHUP, change appropriately
            whenever Promise.in(2) {
                note ‘Timeout. Forcing the process to stop’;
                $proc.kill: SIGKILL
            }
        }
    }

    if $exit-code {
        note "$pdf-prog failed for $source-file, exit-code=$exit-code";
        die X::Agrammon::OutputFormatter::PDF::Failed.new: :$exit-code;
    }
    if $signal {
        note "$pdf-prog killed for $source-file, signal=$signal, reason=$reason";
        die X::Agrammon::OutputFormatter::PDF::Killed.new: :$reason;
    }

    # read content of PDF file created
    my $pdf = $pdf-file.slurp(:bin);

    # cleanup if successful, otherwise kept for debugging.
    unlink $source-file, $pdf-file, $aux-file, $log-file;

    return $pdf;
}

sub latex-escape(Str $in) is export {
    my $out = $in;
    $out ~~ s:g/<[\\]>/\\backslash/;
    $out ~~ s:g/(<[%#{}&$|]>)/\\$0/;
    $out ~~ s:g/(<[~^]>)/\\$0\{\}/;
    # this is a special case for Agrammon as we use __ in
    # the frontend at the momend for indentation in the table
    $out ~~ s:g/__/\\hspace\{2em\}/;
    $out ~~ s:g/_/\\_/;
    return $out;
}

sub latex-chemify(Str $in) is export {
    my $out = $in;
    $out~~ s:g/NOx/\\ce\{NO_\{\(x\)\}\}/;
    $out ~~ s:g/(N2O|NH3|N2|NO2)/\\ce\{$0\}/;
    return $out;
}

sub latex-small-spaces(Str $in) is export {
    my $out = $in;
    $out ~~ s:g/\s+/\\,/;
    return $out;
}

sub format-value($value) {
    sprintf '%.2f', $value;
}

# TODO: make PDF match current Agrammon PDF report
sub input-output-as-pdf(
    Agrammon::Config $cfg,
    Agrammon::Web::SessionUser $user,
    Str $dataset-name, Agrammon::Model $model,
    Agrammon::Outputs $outputs, Agrammon::Inputs $inputs, $reports,
    Str $language, $prints,
    Bool $include-filters, Bool $all-filters
) is export {
    warn '**** input-output-as-pdf() not yet completely implemented';

    my %data = collect-data(
        $dataset-name, $model,
        $outputs, $inputs, $reports,
        $language, $prints,
        $include-filters, $all-filters,
    );

    for %data<outputs> -> @outputs {
        for @outputs -> %rec {
            %rec<unit>  = latex-small-spaces(latex-escape(%rec<unit>));
            %rec<label> = latex-chemify(latex-escape(%rec<label>));
            %rec<value> = format-value(%rec<value>);
        }
    }
    %data<dataset>  = $dataset-name;
    %data<username> = $user.username;
    %data<model>    = $cfg.gui-variant;

    my $pdf = create-pdf(
        $*TMPDIR.add($cfg.general<tmpDir>),
        $cfg.general<pdflatex>,
        $user.username,
        $dataset-name,
        %data
    );
    return $pdf;
}
