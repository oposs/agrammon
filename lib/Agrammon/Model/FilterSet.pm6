use Agrammon::Model::Module;

#| Filters are inputs in a multi module (or one of its dependencies), which can in turn be
#| used to group instances. This identifies the filter inputs for a multi-instance module,
#| including its dependencies, and then can be used to extract them from inputs also.
class Agrammon::Model::FilterSet {
    #| An individual filter field.
    my class Filter {
        has Str $.taxonomy is required;
        has Str $.input-name is required;
        has Str $.filter-key = $!taxonomy ~ '::' ~ $!input-name;
    }

    has Filter @!filters;

    submethod BUILD(Agrammon::Model::Module :$module!, :@dependencies! --> Nil) {
        self!add-from-module($module);
        self!add-from-module($_) for @dependencies;
    }

    method !add-from-module(Agrammon::Model::Module $module --> Nil) {
        for $module.input -> Agrammon::Model::Input $input {
            if $input.is-filter {
                @!filters.push: Filter.new: taxonomy => $module.taxonomy, input-name => $input.name;
            }
        }
    }

    #| Build mapping of filter keys to the matching values for the instance in question.
    method filters-for($multi-input --> Hash) {
        hash @!filters.map: -> Filter $filter {
            with $multi-input.input-hash-for($filter.taxonomy){$filter.input-name} {
                $filter.filter-key => $_
            }
            else {
                warn "Missing filter value for '$filter.input-name()' in $filter.taxonomy() on instance '$multi-input.instance-id()'";
                Empty
            }
        }
    }
}
