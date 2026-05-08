#!/bin/bash
# Optional dev-only init step: set a usable password for the seeded admin
# user (test@agrammon.ch) so a developer can actually log in via the web UI
# against the local podman DB. Gated on AGRAMMON_DEV_PASSWORD: when unset
# (the test-DB case) this script is a no-op, leaving the test seed alone.
#
# Runs after 03-agrammon.test.sql in /docker-entrypoint-initdb.d/ alphabetical
# order, so the row to update already exists. Uses psql -v to safely quote
# the password value.
set -e

if [ -z "$AGRAMMON_DEV_PASSWORD" ]; then
    exit 0
fi

psql -v ON_ERROR_STOP=1 \
     -v dev_pwd="$AGRAMMON_DEV_PASSWORD" \
     --username "$POSTGRES_USER" \
     --dbname "$POSTGRES_DB" <<-'EOSQL'
    UPDATE pers
       SET pers_password = crypt(:'dev_pwd', gen_salt('bf'))
     WHERE pers_email = 'test@agrammon.ch';
EOSQL

echo "Dev password set for test@agrammon.ch"
