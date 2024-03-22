use v6;
use Agrammon::Model;
use Agrammon::Outputs;
use OO::Monitors;

#| Caches the output of running the model against a particular
#| dataset, in order that when we need to produce a report based
#| on those outputs, we do not need to run it again.
class Agrammon::OutputsCache {
    #| The maximum number of datasets that we cache.
    my constant MAX-DATASETS = 5;

    #| The maximum duration that we hold something in the cache,
    #| if it's not invalidated before that point. In seconds.
    my constant MAX-DURATION = 15 * 60;

    #| The cache storage itself is a monitor, for same concurrent
    #| access.
    my monitor Cache {
        #| An entry in the cache.
        my class Entry {
            has Str $.user is required;
            has Str $.dataset is required;
            has Agrammon::Outputs $.outputs is required;
        }

        #| Cache entries. As an array so we can easily delete least
        #| recently used; there just aren't that many entries, so
        #| O(n) lookup is fine.
        has Entry @!entries;

        method find(Str $user, Str $dataset) {
            @!entries.first({ .user eq $user && .dataset eq $dataset })
        }

        method add(Str $user, Str $dataset, Agrammon::Outputs $outputs --> Nil) {
            # Re-check, as two things may both calculate.
            unless self.find($user, $dataset) {
                # Discard least recently used if full.
                if @!entries.elems >= MAX-DATASETS {
                    @!entries.shift;
                }

                # Add entry.
                my $entry = Entry.new(:$user, :$dataset, :$outputs);
                @!entries.push: $entry;

                # Set up invalidation; we do this on the exact entry,
                # since it's possible that another more up to date entry
                # will come to exist in time.
                Promise.in(MAX-DURATION).then: {
                    self.invalidate($entry);
                }
            }
        }

        multi method invalidate(Str $user, Str $dataset --> Nil) {
            @!entries .= grep: { not .user eq $user && .dataset eq $dataset }
        }

        multi method invalidate(Entry $entry --> Nil) {
            @!entries .= grep: { $_ !=== $entry }
        }
    }

    #| The cache storage.
    has Cache $!storage .= new;

    method get-or-calculate(Str $user, Str $dataset, &calculate --> Agrammon::Outputs) {
        with $!storage.find($user, $dataset) {
            # Cache hit, we're good.
            note "Found " ~ .outputs.elems ~ " outputs for user=$user, dataset=$dataset in cache";
            return .outputs;
        }
        else {
            # Calculate, then add the results to the cache.
            my $outputs = calculate();
            note "Got " ~ .outputs.elems ~ " outputs for user=$user, dataset=$dataset from calculate()";
            $!storage.add($user, $dataset, $outputs);
            return $outputs;
        }
    }

    method invalidate(Str $user, Str $dataset --> Nil) {
        $!storage.invalidate($user, $dataset);
    }
}
