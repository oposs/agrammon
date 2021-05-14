use Cro::APIToken::Manager;
use Cro::APIToken::Store::Pg;

my $manager;

#| Obtain the API token manager configured for Agrammon.
sub get-api-token-manager(--> Cro::APIToken::Manager) is export {
    $manager //= Cro::APIToken::Manager.new:
            :40bytes, :prefix<agm>, :checksum,
            store => Cro::APIToken::Store::Pg.new(
                :handle($*AGRAMMON-DB-CONNECTION),
                :table-name<api_tokens> :create-table)
}
