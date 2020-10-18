use Agrammon::Model;

#| Create LaTeX document of Model
sub prepare-model( Agrammon::Model $model, :%technical! ) is export {

    my @sections;
    for $model.evaluation-order.reverse -> $module {

        my @inputs;
        for $module.input -> $input (:$name, :$description, *%) {
            @inputs.push( %( :name(latex-escape($input.name)), :description(latex-escape($input.description)) ) );
        }

        my @outputs;
        for $module.output -> $output (:$name, :$formula, :$description, *%) {
            @outputs.push( %(:name(latex-escape($output.name)), :code($output.code), :$formula, :description(latex-escape($output.description)) ) );
        }

        my $tax = latex-escape($module.taxonomy);

        @sections.push( %(
            :module($tax), :title(Q:s"\subsection{$tax}"), :description(latex-escape($module.description)),
            :@inputs, :@outputs
        ));

    }
    return @sections;
}

sub create-latex( Str $model-name, Agrammon::Model $model, :%technical! ) is export {
    my @sections = prepare-model( $model, :%technical );

    say Qs:to/LATEX/;
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
    \section{Model}
    LATEX

    for @sections -> %section {
        my $module = %section<module>;

        say %section<title>;
        say %section<description>;

        if @(%section<inputs>).elems {
            say '\subsubsection{Inputs}';

            say '\begin{description}';
            for @(%section<inputs>) -> $input {
                say Q:s"\item[$input<name>] $input<description>";
            }
            say '\end{description}';
        }

        if @(%section<outputs>).elems {
            say '\subsubsection{Outputs}';

            say '\begin{description}';
            for @(%section<outputs>) -> $output {
                say Qs:to/LATEX/;
                \item[$output<name>] $output<description>
                \begin{Verbatim}[fontsize=\footnotesize]
                $output<code>
                \end{Verbatim}
                LATEX
            }
            say '\end{description}';
        }

        if %technical{$module}.keys.elems {
            say '\subsubsection{Technical parameters}';

            say '\begin{tabular}{lD{.}{.}{3.3}}';
            for %technical{$module}.kv -> $name, $value {
                say latex-escape($name) ~ ' & ' ~  latex-escape($value) ~ Q:s"\\";
            }
            say '\end{tabular}';
        }
    }
    say '\end{document}';
}

#| Escape LaTeX special characters
sub latex-escape($in) {
    $in.subst(/_/, '\\_', :g)
       .subst(/'%'/, '\\%', :g);
}
