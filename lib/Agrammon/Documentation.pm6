use v6;
use Agrammon::Model;

#| Get model data for LaTeX document generation
sub get-model-data( Agrammon::Model $model, $sort ) {
    my @sections;
    my \order = $sort eq 'calculation' ?? $model.evaluation-order.reverse !! $model.load-order;
    for order -> $module {
        @sections.push( %(
            :module($module.taxonomy),
            :description($module.description),
            :short($module.short),
            :inputs($module.input),
            :outputs($module.output),
            :technicals($module.technical)
        ));
    }
    return @sections;
}

#| Create a LaTeX source of the model
sub create-latex-source( Str $model-name, Agrammon::Model $model, $sort, $doc-sections, :%technical! ) is export {
    my @sections = get-model-data( $model, $sort );

    my @latex;
    @latex.push(latex-preamble($model-name));

    my $last-section = '';
    for @sections -> %section {

        my $module  = %section<module>;
        %technical{$module}:delete unless %technical{$module}.keys;

        next unless any %section<inputs outputs technicals>;
        my $section = $module;
        $section    = ~$0 if $module ~~ / (.+?) '::' /;
        my $title   = latex-escape($module);

        if $section ne $last-section {
            @latex.push(Q:s"\section{Stage $title}");
            $last-section = $section;
        }

        @latex.push(Q:s"\subsection{$title}");

        for $doc-sections.split(',') -> $doc-section {
            @latex.push(latex-escape(%section{$doc-section})) if %section{$doc-section};
        }

        if %section<inputs> {
            @latex.push('\subsubsection*{Inputs}');

            @latex.push('\begin{description}');
            for @(%section<inputs>) -> $input {
                my $name = latex-escape($input.name);
                my $desc = latex-escape($input.description);
                @latex.push(Q:s"\item[$name] $desc");
            }
            @latex.push('\end{description}');
        }

        if %section<outputs> {
            @latex.push('\subsubsection*{Outputs}');

            @latex.push('\begin{description}');
            for @(%section<outputs>) -> $output {
                my $name = latex-escape($output.name);
                my $desc = latex-escape($output.description);
                my $code = $output.code;
                # don't indent content of HEREDOC as this will
                # add excessive indentation on $code's first line
                @latex.push(Qs:to/LATEX/);
                \item[$name] $desc
                \begin{Verbatim}[fontsize=\footnotesize]
                $code
                \end{Verbatim}
                LATEX
            }
            @latex.push('\end{description}');
        }

        if %section<technicals> {
            @latex.push('\subsubsection*{Technical Parameters}');

            @latex.push('\begin{description}');
            for @(%section<technicals>) -> $technical {
                my $unit = latex-escape($technical<units><en> // '');
                $unit = '' if $unit eq '-';
                my $name = latex-escape($technical.name);
                my $desc = latex-escape($technical.description // '');
                my $value = %technical{$module}{$technical.name} // '???';
                @latex.push(Q:s"\item[$name] $value $unit\\ $desc");
                %technical{$module}{$technical.name}:delete;
            }
            @latex.push('\end{description}');
            %technical{$module}:delete unless %technical{$module}.keys;
        }
        @latex.push('\clearpage');

    }

    if %technical.keys {
        @latex.push('\section{Unused technical parameters}');
        @latex.push('\textbf{This section should not exist!}');
        @latex.push('\begin{description}');
        for %technical.kv -> $module, %param {
            for %param.kv -> $name, $value {
                @latex.push(Q:s"\item[$module] " ~ latex-escape($name) ~ "= $value");
            }
        }
        @latex.push('\end{description}');
    }
    @latex.push(latex-closing);
    @latex.join("\n");
}

sub latex-preamble($model-name) {
    Qs:to/LATEX/;
        \documentclass[11pt]{article}
        \usepackage[a4paper,top=1.5cm,bottom=2.0cm,left=2cm,right=2cm]{geometry}
        \usepackage[utf8]{luainputenc}
        \usepackage{hyphenat}
        \usepackage[T1]{fontenc}
        \usepackage[default]{opensans}
        \usepackage{parskip}
        \usepackage{fancyhdr}
        \usepackage{xcolor}
        \usepackage{graphicx}
        \usepackage{fancyvrb}
        %\usepackage{longtable}
        \usepackage{dcolumn}

        \pagestyle{fancy}
        \setlength\headheight{54.66464pt}

        \newenvironment{todo}[2]{\textbf{TODO (#1):} }{}

        \begin{document}
        \begin{titlepage}
        \title{Model: $model-name}
        \end{titlepage}
        \maketitle
        \tableofcontents
        \clearpage
        % \section{Model}
    LATEX
}

sub latex-closing {
    '\end{document}'
}

#| Escape LaTeX special characters
sub latex-escape($in) {
    $in.subst(/_/, '\\_', :g)
        .subst(/'%'/, '\\%', :g)
        .subst(/'#'/, '\\#', :g)
    ;
}
