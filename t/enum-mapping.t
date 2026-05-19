use v6;
use Agrammon::ModuleBuilder;
use Agrammon::ModuleParser;
use Test;

# Verifies cross-version enum alias declarations in the shipped model
# files (production data, unlike t/enum-aliases.rakutest which uses a
# synthetic test fixture).

plan 1;

subtest "v6 to v7" => {
    plan 9;

    my $file = $*PROGRAM.parent.parent
                 .add('share/Models/version6.5.2/Livestock/Poultry/Grazing.nhd');
    my $parsed = Agrammon::ModuleParser.parsefile(
        ~$file,
        actions => Agrammon::ModuleBuilder.new
    );
    ok $parsed, 'Grazing.nhd parses';

    my $module = $parsed.ast;
    my $free-range = $module.input.first({ .name eq 'free_range' });
    ok $free-range.defined,        'free_range input present';
    is $free-range.type, 'enum',   'type is enum';

    # 6.5.2 local options.
    is $free-range.enum-ordered.map(*.key).sort.list, <no yes>,
        'local options are yes/no';

    # 7.0.0 introduced 'mobile' as a separate option; 6.5.2 accepts it
    # as an alias for the combined 'yes' so v7-tagged datasets opened
    # here validate and canonicalize correctly.
    ok $free-range.is-valid-enum-value('mobile'),
        "7.0.0 'mobile' accepted as alias";
    is $free-range.canonical-enum-value('mobile'), 'yes',
        "7.0.0 'mobile' canonicalizes to 6.5.2 'yes'";

    # Native values keep working.
    ok $free-range.is-valid-enum-value('yes'), "native 'yes' valid";
    ok $free-range.is-valid-enum-value('no'),  "native 'no' valid";
    nok $free-range.is-valid-enum-value('bogus'),
        'unknown value rejected';
};

done-testing;
