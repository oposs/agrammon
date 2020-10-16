use Agrammon::Model;

#| Create LaTeX document of Model
sub create-latex( Agrammon::Model $model, :%technical! ) is export {

    my @sections;
    for $model.evaluation-order.reverse -> $module {

        my @inputs;
        for $module.input -> $input (:$name, :$description, *%) {
            @inputs.push( %( :name(latex-escape($input.name)), :description(latex-escape($input.description)) ) );
        }

        my @outputs;
        for $module.output -> $output (:$name, :$formula, :$description, *%) {
            @outputs.push( %(:name(latex-escape($output.name)), :$formula, :description(latex-escape($output.description)) ) );
        }

        my $tax = latex-escape($module.taxonomy);

        @sections.push( %(
            :title(Q:s"\subsection{$tax}"), :description(latex-escape($module.description)),
            :@inputs, :@outputs
        ));

    }
    return @sections;
}

#| Escape LaTeX special characters
sub latex-escape($in) {
    $in.subst(/_/, '\\_', :g);
}
