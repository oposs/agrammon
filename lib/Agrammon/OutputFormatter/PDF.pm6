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

sub create-pdf($temp-dir-name, $pdf-prog, $username, $dataset-name, %data) is export {
    # setup temp dir and files
    my $temp-dir = $*TMPDIR.add($temp-dir-name);
    if not  $temp-dir.e {
        $temp-dir.mkdir;
        note "Created temp-dir $temp-dir";
    }

    my $filename = "agrammon_export_" ~ $username ~ "_$dataset-name";
    my $source-file = "$temp-dir/$filename.tex".IO;
    my $pdf-file    = "$temp-dir/$filename.pdf".IO;
    my $aux-file    = "$temp-dir/$filename.aux".IO;
    my $log-file    = "$temp-dir/$filename.log".IO;

    # create LaTeX source with template
    $source-file.spurt(create-latex('pdfexport', %data));

    # create PDF, discard STDOUT and STDERR (see .log file if necessary)
    my $exit-code;
    my $signal;
    my $reason = 'Unknown';

    # don't use --safer
    my $proc = Proc::Async.new: :w, $pdf-prog,
            "--output-directory=$temp-dir",  '--no-shell-escape', '--', $source-file, ‘-’;

    react {
        # just ignore any output
        whenever $proc.stdout.lines {
        }
        whenever $proc.stderr {
        }
        whenever $proc.start {
            $exit-code = .exitcode;
            $signal    = .signal;
            done; # gracefully jump from the react block
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
    unlink $source-file, $pdf-file, $aux-file, $log-file unless %*ENV<AGRAMMON_KEEP_FILES>;

    return $pdf;
}

sub latex-escape(Str $in) is export {
    my $out = $in;
    $out ~~ s:g/<[\\]>/\\backslash/;
    $out ~~ s:g/(<[%#{}&$|]>)/\\$0/;
    $out ~~ s:g/(<[~^]>)/\\$0\{\}/;
    # this is a special case for Agrammon as we use __ in
    # the frontend at the moment for indentation in the table
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
    latex-escape($value);
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

    # get data ready for printing
    my %data = collect-data(
        $dataset-name, $model,
        $outputs, $inputs, $reports,
        $language, $prints,
        $include-filters, $all-filters,
    );

    # strings used in template
    my %titles = %(
        report =>  %(
            :de('Emissionsberechnung für Ammoniak mit Agrammon'),
            :en('Calculation for ammonia emissions with Agrammon'),
            :fr('Calcul des émissions d’ammoniac avec Agrammon'),
        ){$language},
        data => %(
            section => %(
                :de('Angaben zu Nutzer/-in und Datensatz'),
                :en('Information on the user and the dataset'),
                :fr('Informations sur l’utilisateur/-trice et sur le set de données'),
            ){$language},
            user => %(
                :de('Benutzername'),
                :en('Username'),
                :fr('Nom d’utilisateur'),
            ){$language},
            dataset => %(
                :de('Datensatz'),
                :en('Dataset'),
                :fr('Set de données'),
            ){$language},
        ),
        outputs => %(
            :de('Ergebnis der Emissionsberechnung'),
            :en('Results of the emission calculation'),
            :fr('Résultats du calcul des émissions')
        ){$language},
        outputLog => %(
            :de('Mitteilungen zu den Resultaten'),
            :en('Notes on the results'),
            :fr('Messages concernant les résultats'),
        ){$language},
        inputs => %(
            :de('Eingaben Datensatz'),
            :en('Input parameters of the dataset'),
            :fr('Paramétres d’entrée du set de données'),
        ){$language}
    );

    my @prints = $reports[+$prints]<data>;
    my %lang-labels;
    my @print-set;
    for @prints -> @print {
        for @print -> $print {
            @print-set.push($print<print>);
            %lang-labels{$print<print>} = $print<langLabels>;
        }
    }

    my @output-formatted;
    my $last-print = '';
    my $first = True;
    for %data<outputs> -> @outputs {
        for @outputs.sort(+*.<order>) -> %rec {
            my $print = %rec<print>; # can be undefined or empty
            if $print and $print ne $last-print {
                @output-formatted.push(%(
                    :section(%lang-labels{$print}{$language} // 'NO-TITLE'),
                    :$first));
                $first = False if $first;
                $last-print = $print;
            }
            @output-formatted.push(%(
                :unit(latex-small-spaces(latex-escape(%rec<unit>))),
                :label(latex-chemify(latex-escape(%rec<label>))),
                :value(format-value(%rec<value>))));
        }
    }

    my @input-formatted;
    # TODO: fix sorting
    my @inputs := %data<inputs>;
# left on purpose
#    dd @inputs[0];
    $last-print = '';
    my $last-instance = '';
    my $last-module = '';
    my $first-module = True;
    my $first-instance = True;
    for @inputs -> %rec {
        my $new-module = False;
        my $new-instance = False;

        my $module = %rec<gui>;
        if $module ne $last-module {
            @input-formatted.push( %(
                :module(latex-escape($module)),
                :$first-module));
            $last-module = $module;
            $new-module = True;
            $first-module = False;
            $first-instance = True;
        }

        # instance can be empty for none-multi modules
        my $instance = %rec<instance>;
        if $instance and $instance ne $last-instance {
            @input-formatted.push( %(
                :instance(latex-escape($instance)),
                :$first-instance));
            $last-instance = $instance;
            $new-instance = True;
            $first-instance = False;
        }

        my $first-line = $new-module && ! $new-instance;

        @input-formatted.push(%(
            :unit(latex-small-spaces(latex-escape(%rec<unit>))),
            :label(latex-chemify(latex-escape(%rec<input>))),
            :value(format-value(%rec<value-translated>)),
            :$first-line));
    }

    # setup template data
    %data<outputs>   = @output-formatted;
    %data<inputs>    = @input-formatted;
    %data<titles>    = %titles;
    %data<dataset>   = $dataset-name;
    %data<username>  = $user.username;
    %data<model>     = $cfg.gui-variant;
    %data<version>   = 'Agrammon 6.0';
    %data<timestamp> = ~DateTime.now( formatter => sub ($o) {
        sprintf '%02d.%02d.%04d %02d:%02d:%02d',
            $o.day, $o.month, $o.year,
            $o.hour, $o.minute, $o.second,
    });

   return create-pdf(
        $*TMPDIR.add($cfg.general<tmpDir>),
        $cfg.general<pdflatex>,
        $user.username,
        $dataset-name,
        %data
    );
}
