# Local development with the podman PostgreSQL DB

This setup gives you a persistent local PostgreSQL container (separate from
the ephemeral test DB used by CI) plus a web-app launcher pointed at it.
Datasets you create through the GUI survive container restarts.

## One-time setup

Build dependencies are the same as the existing test DB workflow (podman
must be installed and `t/Dockerfile` must be buildable). The `init` scripts
under `t/` ship the schema and a single seeded admin user
(`test@agrammon.ch`).

## Daily workflow

```bash
# Start the dev DB (builds the image on first run, idempotent thereafter)
make dev-db-start

# Run the web app
./runWebDev.sh

# In another terminal: open http://localhost:20000 and log in as
#   test@agrammon.ch  /  agrammon
```

When you're done:

```bash
# Stops and removes the container; data persists in dev/db-data/
make dev-db-stop
```

## Useful targets

| Target              | What it does                                              |
| ------------------- | --------------------------------------------------------- |
| `dev-db-start`      | Build image (if needed) and start the container.          |
| `dev-db-stop`       | Stop and remove the container. Data persists.             |
| `dev-db-restart`    | Stop + start.                                             |
| `dev-db-logs`       | Tail the container log.                                   |
| `dev-db-psql`       | Open a psql shell as `agrammon`.                          |
| `dev-db-reset`      | Stop the container and **wipe `dev/db-data/`**. Next start re-runs the schema/seed scripts. Use this after schema changes. |

## How it differs from the test DB

|                       | Test DB (`make db-start`)        | Dev DB (`make dev-db-start`)         |
| --------------------- | -------------------------------- | ------------------------------------ |
| Container name        | `agrammon-postgres`              | `agrammon-dev-db`                    |
| Host port             | `55432`                          | `55433`                              |
| Data directory        | container-internal (ephemeral)   | bind-mount `dev/db-data/` (persistent) |
| Admin password        | placeholder, login won't work    | `agrammon` (override via `DEV_DB_PASSWORD=...`) |
| Init scripts re-run?  | every fresh start                | only on first start (re-init via `dev-db-reset`) |

The two can run side by side — different ports, different containers.

## Variables

```bash
make dev-db-start \
  DEV_DB_PORT=55444 \
  DEV_DB_DATA=/some/other/path/dev/db-data \
  DEV_DB_PASSWORD=mySecret
```

`DEV_DB_DATA` must end in `/dev/db-data` for `dev-db-reset` to delete it
(safety check).

## Notes

- Schema/seed changes in `t/test-data/agrammon.schema.sql` or
  `t/test-data/agrammon.test.sql` only affect a fresh DB. To pick them up,
  run `make dev-db-reset` (this destroys your dev datasets).
- The seeded admin user is the same row as the test seed; the dev-only
  `t/04-dev-password.sh` init script overrides its password to a usable
  value when `AGRAMMON_DEV_PASSWORD` is set in the container env.
