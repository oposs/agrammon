#| When we have a multi-instance module, the instances may have filters applied.
#| Traditionally when dealing with instances in aggregate, we just obtained the
#| sum and used that. However, with instance filters, we want to track the numbers
#| by filter groups, and to do math operations pairwise on those groups. This class
#| represents both a total value and the breakdown by filter group. It provides a
#| means to do operations on them.
class Agrammon::Outputs::FilterGroupCollection {
    #| A value object set of filter keys
    my class FilterKey {
        has %.filters is required;
        has ValueObjAt $!WHICH = ValueObjAt.new:
                'FilterKey|' ~ %!filters.sort(*.key).map({ .key ~ '=' ~ .value }).join("\0");

        multi method WHICH(FilterKey:D:) {
            $!WHICH
        }

        method empty() {
            self.new(:filters{})
        }
    }

    has Numeric %!values-by-filter{FilterKey};
    has Set $.provenance;

    submethod BUILD(:$!provenance = ∅, :@instances!) {
        for @instances {
            %!values-by-filter{.key} += .value;
        }
    }

    #| Create a filter group from a simple scalar value.
    method from-scalar(Numeric $value) {
        self.bless: instances => [FilterKey.empty => $value]
    }

    #| Create from a list of pairs where the key is a hash of filter values for an instance
    #| and the value is the instance's value.
    method from-filter-to-value-pairs(@instances, Set :$provenance = ∅) {
        self.bless:
                :instances(@instances.map({ FilterKey.new(filters => .key) => +.value })),
                :$provenance
    }

    #| Check if the collection has any filters.
    method has-filters(--> Bool) {
        so %!values-by-filter.keys.first(*.filters.elems)
    }

    #| Get the overall total value.
    method Numeric() {
        %!values-by-filter.values.sum
    }

    #| Get the overall total value.
    method Real() {
        self.Numeric.Real
    }

    #| Get a list of pairs mapping filter groups into the total value for that
    #| group. If :all is passed, then all filters that could possibly have been
    #| selected will be included, even if no instance used them, and they will
    #| have a zero value.
    method results-by-filter-group(Bool :$all = False) {
        if $all {
            if %!values-by-filter && !$!provenance {
                die "Can only get all values when provenance of the filter group was provided";
            }
            my @results;
            for $!provenance.keys.sort(*.module.taxonomy).reverse -> $filter-set {
                for $filter-set.all-possible-filter-keys -> %filters {
                    my $key = FilterKey.new(:%filters);
                    @results.push(%filters => %!values-by-filter{$key} // 0);
                }
            }
            with %!values-by-filter{FilterKey.empty} {
                @results.push({} => $_);
            }
            @results
        }
        else {
            [%!values-by-filter.map({ .key.filters => .value })]
        }
    }

    #| Produce a new filter group collection which has the values of this one scaled by
    #| the specified factor. This can be used to implement `scalar * group`, `group * scalar`
    #| (these two just commute), and `group / scalar` (by passing in `1 / scalar` as the
    #| factor).
    method scale(Numeric $factor --> Agrammon::Outputs::FilterGroupCollection) {
        self.bless:
                :instances(%!values-by-filter.map({ .key => $factor * .value })),
                :$!provenance
    }

    #| Produce a new filter group collection which has the values of this one added to
    #| a specified additor. This can be used to implement `scalar + group`, `group + scalar`
    #| (these two just commute), and `group - scalar` (by passing in `- scalar` as the
    #| additor).
    method add(Numeric $factor --> Agrammon::Outputs::FilterGroupCollection) {
        self.bless:
                :instances(%!values-by-filter.map({ .key => $factor + .value })),
                :$!provenance
    }

    #| Produce a new filter group collection which has the sign of this one.
    method sign() {
        self.bless:
                :instances(%!values-by-filter.map({ .key => sign( .value ) })),
                :$!provenance
    }

    #| Apply an operation pairwise between this group collection and another one, returning a
    #| new group collection as the result. When a group exists in collections, then the operation
    #| is applied to their values. When a group exists on only one side, the base value is used.
    method apply-pairwise(Agrammon::Outputs::FilterGroupCollection $other, &operation, Numeric $base) {
        # Process those groups existing on both sides or only the other side.
        my @result-instances;
        my Bool %seen-from-this-instance{FilterKey};
        for $other!internal-values-by-filter -> $their-elem {
            my $their-key = $their-elem.key;
            with %!values-by-filter{$their-key} -> $our-value {
                # Exists on both sides.
                @result-instances.push: $their-key => operation($our-value, $their-elem.value);
                %seen-from-this-instance{$their-key} = True;
            }
            else {
                # Exists only on their side.
                @result-instances.push: $their-key => operation($base, $their-elem.value);
            }
        }

        # We now look for anything that only existed on our side.
        if %seen-from-this-instance.elems < %!values-by-filter.elems {
            for %!values-by-filter -> $our-elem {
                unless %seen-from-this-instance{$our-elem.key} {
                    @result-instances.push: $our-elem.key => operation($our-elem.value, $base);
                }
            }
        }

        Agrammon::Outputs::FilterGroupCollection.new:
                instances => @result-instances,
                provenance => $!provenance ∪ $other.provenance
    }

    #| Check in the other filter group collection for values that are greater than a threshold
    #| and return a new group collection as the result. When $push-all is False, then the method
    #| returns only filter groups where $thresh is exceeded. Otherwise, if $push-all is True,
    #| filter groups where $thresh is not exceeded are also returned with a value of $thresh.
    method select-by-threshold(Agrammon::Outputs::FilterGroupCollection $other, Numeric $thresh, Bool $push-all) {
        # Only process those groups existing on the other side.
        my @result-instances;
        for $other!internal-values-by-filter -> $their-elem {
            my $their-key = $their-elem.key;
            if $their-elem.value > $thresh {
                my $our-value = %!values-by-filter{$their-key};
                if $our-value.defined {
                    # Push our value if their value > threshold
                    @result-instances.push: $their-key => $our-value;
                }
                else {
                    # Push 0 if their value > threshold, but key is not existing
                    # 0 because of missing flow (zero flow)
                    @result-instances.push: $their-key => 0;
                }
            }
            elsif $push-all {
                # Push threshold if their value <= threshold. Could also be 0,
                # but it might become handy for limiting ratio to 1, i.e. threshold = 1?
                @result-instances.push: $their-key => $thresh;
            }
        }

        Agrammon::Outputs::FilterGroupCollection.new:
                :instances(@result-instances), :$!provenance
    }

    #| Private accessor to get internal representation of another collection.
    method !internal-values-by-filter() {
        %!values-by-filter
    }
}
