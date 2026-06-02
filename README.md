# Agrammon

## The simulation model

Ammonia volatilisation is a significant source of nitrogen (N) loss in
agriculture.  Almost one-third of the N load of farmyard manure is lost this
way, resulting in both a financial loss as well as diminished productivity
for the farmer.  At the same time, ammonia emissions are detrimental to the
environment, in particular to natural ecosystems.

The simulation model Agrammon allows ammonia emissions to be calculated, and
shows how changes in structure and production methods at the farm level
affect emissions.

The model was developed by the [Swiss College of Agriculture
(SHL)](http://www.shl.bfh.ch/) and the companies [Bonjour Engineering
GmbH](http://http://www.ecodata.ch) and [Oetiker+Partner
AG](https://www.oetiker.ch), with support from the [Federal Office for the
Environment (FOEN)](https://www.bafu.admin.ch/bafu/en/home.html).

Please see the [Agrammon website](https://www.agrammon.ch) for more details.

## Port to Raku

This is a port of the existing Agrammon web application to Raku.  It was
finished by Christmas.

## Development setup

You'll need to:

1. Install `rakudo` and `zef`.
2. Install the Raku dependencies — this also installs the pinned patched Cro
   builds (see below): `make deps`
   (equivalently: `./install-patched-deps.sh && zef install --deps-only .`).
3. Install `typst` for PDF export — a single static binary from
   <https://github.com/typst/typst/releases>; optionally `ghostscript` for PDF
   stream re-compression. Point `General.typst` in the YAML config at it.

### Patched Cro dependencies (temporary)

Two upstream Cro fixes Agrammon needs are **merged but not yet released**, so
`zef install --deps-only .` on its own would pull the stock (unfixed) builds.
`install-patched-deps.sh` — run by `make deps` / `make install-modules`, the
Docker build, and `make deploy-deps` — installs them first, pinned to their
merge commits, so the stock builds are not pulled over them:

- **Cro::HTTP** — `Cro::HTTP::Middleware::Conditional` never completes its
  per-connection `early-responses` Supplier, leaking RSS on every request
  through any `before`/`after` route block or token-auth middleware.
  Fix merged: <https://github.com/croservices/cro-http/pull/214>.
- **Cro::OpenAPI::RoutesFromDefinition** — under Cro::HTTP::Router 0.8.12+ the
  OpenAPI route `include` crashes with "No such method 'name'".
  Fix merged: <https://github.com/croservices/cro-openapi-routes-from-definition/pull/15>.

Once each fix is released to the Raku ecosystem, drop its line from
`install-patched-deps.sh` and rely on normal `zef` resolution (plus the
META6.json version bound).

## Running tests

Run tests using `prove6 -l t/`. If missing `prove6`, you can install it with
`zef install App::Prove6`.

To only run unit tests, set `AGRAMMON_UNIT_TEST=1` in the environment.  The
integration tests currently have quite some setup dependencies; this should
be addressed in the future.

## Database setup (PostgreSQL)

Install or use existing PostgreSQL database server:

CREATE GROUP agrammon_user;
CREATE USER agrammon;
ALTER GROUP agrammon_user ADD USER agrammon;
CREATE DATABASE agrammon OWNER agrammon;

Load a database dump (auto creation not yet implemented)

## Installation Web App

apt install libnsl-dev

Install npm and jq from your distro and then run

mkdir -p public # first time only
./bootstrap
./configure
./make

Point your config file to the Agrammon database.
Adapt runWeb.sh to point to your config file and model.

./runWeb.sh

and point your browser to the shown URL (defaults to localhost:20000)

## REST Api

The Agrammon model can be accessed via a REST interface, for details see the
[online documentation](https://redocly.github.io/redoc/?url=https://model.agrammon.ch/single/api/v1/openapi.yaml)
