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

    submethod BUILD(:@instances!) {
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
    method from-filter-to-value-pairs(@instances) {
        self.bless: instances => @instances.map({ FilterKey.new(filters => .key) => +.value })
    }

    #| Get the overall total value.
    method Numeric() {
        %!values-by-filter.values.sum
    }

    #| Get a list of pairs mapping filter groups into the total value for that group.
    method results-by-filter-group() {
        [%!values-by-filter.map({ .key.filters => .value })]
    }
}
