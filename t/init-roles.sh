#!/bin/bash
set -e

# Create roles before database initialization
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create role if it doesn't exist
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'agrammon') THEN
            CREATE ROLE agrammon WITH LOGIN PASSWORD 'agrammon';
        END IF;
    END
    \$\$;
    -- Create role if it doesn't exist
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'agrammon_user') THEN
            CREATE ROLE agrammon_user WITH LOGIN PASSWORD 'agrammon';
        END IF;
    END
    \$\$;

    -- Change database ownership to agrammon user
    ALTER DATABASE $POSTGRES_DB OWNER TO agrammon;

    -- Grant privileges
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO agrammon;
    -- GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO agrammon_user;
EOSQL

echo "Roles created successfully"
