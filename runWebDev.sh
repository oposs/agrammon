#! /bin/bash
# Run the web app against the local podman dev database (see Makefile
# `make dev-db-start`). The DB persists across container restarts via the
# bind mount in dev/db-data/. Default login: test@agrammon.ch / agrammon.
set -e

cd "$(dirname "$0")"

if ! podman container exists agrammon-dev-db 2>/dev/null; then
    echo "Dev DB container not running. Start it first with: make dev-db-start" >&2
    exit 1
fi

# SOURCE_MODE=1 makes the Cro static-content routes serve the qooxdoo
# source target (frontend/compiled/source/) instead of the production
# build target (public/). Frontend edits then pick up after a single
# `npx qx compile` (or live via `npx qx compile --watch`) without
# needing a full minified rebuild.
export SOURCE_MODE=1
exec raku -Ilib bin/agrammon.raku --cfg-file=dev/agrammon.dev.yaml web version6/End.nhd
