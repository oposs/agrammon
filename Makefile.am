#  Copyright (C) 2023 Fritz Zaucker

AUTOMAKE_OPTIONS =  foreign

# SUBDIRS = thirdparty etc frontend
SUBDIRS = frontend

PUB := $(shell find -L public -type d \( -name ".??*" -o -name transpiled \) -prune -o -not -name "*db.json" -a -not -name "*.map" -a -not -name "*~" -a -not -name transpiled -a -not -name "*.tmp"  -a -type f -print )

TEMPL := $(shell test -d templates && find -L templates -type f -name "*.ep")
SHARE := $(shell test -d share && find -L share -type d -name ".??*" -prune -o -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp"  -a -not -path "share/Models/Experimental/*" -a -type f -print)

PERLTESTS := $(shell find t -name "*.t")
PM := $(shell find lib -name "*.pm")

# EXTRA_DIST = VERSION cpanfile COPYRIGHT LICENSE CHANGELOG AUTHORS bootstrap $(PUB) $(wildcard t/*.t) $(POD) $(TEMPL) $(PERLTESTS) $(SHARE) Dockerfile

EXTRA_DIST = META6.json README.md VERSION COPYRIGHT CHANGELOG.md bootstrap $(PUB) $(wildcard t/*.t) $(POD) $(TEMPL) $(PERLTESTS) $(SHARE) bin lib db

# Default gzip --best is ~6× slower than -6 for marginal size gain on
# our 250 MB tree. Override automake's default so `make dist` finishes
# in seconds rather than minutes.
GZIP_ENV = -6

# Strip dev-host caches from the dist tarball. `lib/.precomp` is a
# symlink to /scratch/.../lib/precomp on the developer host; automake's
# `tar -ch` follows it, pulling in ~250 MB of stale .moarvm files that
# only confuse Rakudo on prod (different compunit identity, different
# Rakudo version — exact cause of the 2026-05-24 SIGSEGV episode).
# Prod wipes ~/.agrammon/.precomp on every deploy anyway.
dist-hook:
	find $(distdir) -name .precomp -prune -exec rm -rf {} +

# Keep the build's version in sync with META6.json (the source of truth;
# AC_INIT pulls it via m4_esyscmd at autoconf time). Two safeguards:
#  1. Auto-rebuild: make CONFIGURE/CONFIG_STATUS depend on META6.json so
#     `make` re-runs autoconf + config.status --recheck when it changes
#     (needs maintainer-mode, enabled in configure.ac). m4_esyscmd's result
#     is cached in autom4te.cache, so the AUTOCONF override clears it first;
#     otherwise the re-read would keep serving the stale version.
#  2. check-version fails `make dist` loudly if the configured version is
#     still stale (e.g. built with --disable-maintainer-mode), turning the
#     silent "shipped the old version" footgun into a clear error.
CONFIGURE_DEPENDENCIES = $(top_srcdir)/META6.json
CONFIG_STATUS_DEPENDENCIES = $(top_srcdir)/META6.json
AUTOCONF = rm -rf $(top_srcdir)/autom4te.cache && $(SHELL) $(top_srcdir)/conftools/missing autoconf

.PHONY: check-version
check-version:
	@src=`jq -r .version < $(top_srcdir)/META6.json`; \
	if test "x$$src" != "x$(PACKAGE_VERSION)"; then \
	  echo "*** META6.json version ($$src) != configured ($(PACKAGE_VERSION))"; \
	  echo "*** run ./bootstrap && ./configure before make dist"; \
	  exit 1; \
	fi

dist: check-version

.PHONY: help

help:
	@echo "Agrammon — Makefile targets"
	@echo ""
	@echo "Setup:"
	@echo "  deps              Install Raku (zef) dependencies"
	@echo "  install-modules   Install Agrammon modules + deps into local Raku (zef)"
	@echo ""
	@echo "Build / dist (automake):"
	@echo "  all               Build everything (default automake target)"
	@echo "  dist              Create distribution tarball"
	@echo "  distcheck         Create tarball and run its tests"
	@echo "  install           Install built artifacts"
	@echo "  clean             Remove build artifacts"
	@echo ""
	@echo "Test database (podman, ephemeral):"
	@echo "  db-build          Build the test DB container image"
	@echo "  db-start          Start the test DB container (port \$$DB_PORT=$(DB_PORT))"
	@echo "  db-stop           Stop and remove the test DB container"
	@echo "  db-restart        Restart the test DB container"
	@echo "  db-logs           Show test DB container logs"
	@echo "  db-psql           Open psql against the test DB"
	@echo ""
	@echo "Tests:"
	@echo "  test              Run full test suite (needs test DB running)"
	@echo "  unit-test         Run only unit tests (skip DB-backed tests)"
	@echo ""
	@echo "Development database (podman, persistent):"
	@echo "  dev-db-start      Start dev DB with bind-mounted data (port \$$DEV_DB_PORT=$(DEV_DB_PORT))"
	@echo "  dev-db-stop       Stop and remove dev DB container"
	@echo "  dev-db-restart    Restart dev DB container"
	@echo "  dev-db-logs       Show dev DB container logs"
	@echo "  dev-db-psql       Open psql against the dev DB"
	@echo "  dev-db-reset      Wipe dev DB data dir so init scripts re-run on next start"
	@echo ""
	@echo "Deployment (bare-metal web-volki-01, no k8s):"
	@echo "  deploy            Build + swap app code on the server, wipe precomp, restart units"
	@echo "  deploy-deps       Refresh Raku deps on the server, restart"
	@echo ""
	@echo "Container image (multi-stage Dockerfile → $(CONTAINER_REGISTRY)):"
	@echo "  image             Build the container image locally"
	@echo "  image-push        Build and push to $(CONTAINER_REGISTRY) (login required)"
	@echo "  image-test        Build + push with CONTAINER_ENV=test  (= $(CONTAINER_IMAGE):test-…)"
	@echo "  image-prod        Build + push with CONTAINER_ENV=prod  (= $(CONTAINER_IMAGE):prod-…)"
	@echo "  image-print       Show what \`image\` would build (resolves tag etc.)"
	@echo ""
	@echo "Variables (override on command line, e.g. make db-start DB_PORT=5555):"
	@echo "  PODMAN=$(PODMAN)"
	@echo "  DB_IMAGE=$(DB_IMAGE)  DB_CONTAINER=$(DB_CONTAINER)  DB_PORT=$(DB_PORT)"
	@echo "  DEV_DB_CONTAINER=$(DEV_DB_CONTAINER)  DEV_DB_PORT=$(DEV_DB_PORT)"
	@echo "  DEV_DB_DATA=$(DEV_DB_DATA)"
	@echo "  CONTAINER_REGISTRY=$(CONTAINER_REGISTRY)"
	@echo "  CONTAINER_PROJECT=$(CONTAINER_PROJECT)"
	@echo "  CONTAINER_IMAGE=$(CONTAINER_IMAGE)"
	@echo "  CONTAINER_ENV=$(CONTAINER_ENV)  CONTAINER_VERSION=$(CONTAINER_VERSION)"
	@echo "  CONTAINER_TAG=$(CONTAINER_TAG)"

deps:
		zef --debug --/test --deps-only --test-depends install .

.PHONY: install-modules

# Install Agrammon's own modules (and their dependencies) into the user's
# local Raku installation. --force-install allows re-installing over an
# existing same-version copy during development.
install-modules:
		zef install --/test --force-install .

# --- Deployment to web-volki-01 (bare-metal, no k8s) --------------------------
#
# make deploy       Build a release tarball and swap the APP CODE on the server,
#                   wipe the precomp cache (stale precomp SIGSEGVs after a swap),
#                   and restart the target units. Build the frontend first if it
#                   changed: (cd frontend && make build).
# make deploy-deps  Refresh the Raku deps on the server, then restart. Run when
#                   META6.json changed; the release must already be unpacked
#                   (run `make deploy` first).
#
# Defaults target the TEST single siblings. Override for prod / other instances:
#   make deploy DEPLOY_UNITS='agrammon.prod.SingleVersion6.5.2.service agrammon.prod.SingleVersion7.0.0.service'
DEPLOY_HOST    ?= agrammon@web-volki-01-adm
DEPLOY_VERSION ?= $(shell cat VERSION)
DEPLOY_RELEASE ?= agrammon-$(DEPLOY_VERSION)
RELEASES_DIR   ?= opt/releases
DEPLOY_UNITS   ?= agrammon.test.SingleVersion6.5.2.service agrammon.test.SingleVersion7.0.0.service
# zef/rakudo live on the deploy user's login PATH only; a non-login ssh does not
# source the profile, so deploy-deps exports it explicitly. Override if rakudo
# is installed elsewhere on the target.
DEPLOY_RAKU_BIN ?= $$HOME/opt/rakudo/bin:$$HOME/opt/rakudo/share/perl6/site/bin

.PHONY: deploy deploy-deps

deploy: dist
	scp $(DEPLOY_RELEASE).tar.gz $(DEPLOY_HOST):src/
	ssh $(DEPLOY_HOST) 'set -e; \
	  systemctl --user stop $(DEPLOY_UNITS); \
	  cd "$$HOME/$(RELEASES_DIR)"; \
	  rm -rf "$(DEPLOY_RELEASE).bak"; \
	  [ ! -d "$(DEPLOY_RELEASE)" ] || mv "$(DEPLOY_RELEASE)" "$(DEPLOY_RELEASE).bak"; \
	  tar zxf "$$HOME/src/$(DEPLOY_RELEASE).tar.gz"; \
	  rm -rf "$$HOME/.agrammon/.precomp" "$$HOME/.agrammon"/*.rakumod; \
	  systemctl --user reset-failed $(DEPLOY_UNITS) 2>/dev/null || true; \
	  systemctl --user start $(DEPLOY_UNITS)'
	@echo "Deployed $(DEPLOY_RELEASE) to $(DEPLOY_HOST) [units: $(DEPLOY_UNITS)]"

deploy-deps:
	ssh $(DEPLOY_HOST) 'set -e; \
	  export PATH="$(DEPLOY_RAKU_BIN):$$PATH"; \
	  cd "$$HOME/$(RELEASES_DIR)/$(DEPLOY_RELEASE)"; \
	  zef install --/test --deps-only .; \
	  systemctl --user stop $(DEPLOY_UNITS); \
	  rm -rf "$$HOME/.agrammon/.precomp" "$$HOME/.agrammon"/*.rakumod; \
	  systemctl --user reset-failed $(DEPLOY_UNITS) 2>/dev/null || true; \
	  systemctl --user start $(DEPLOY_UNITS)'
	@echo "Refreshed deps for $(DEPLOY_RELEASE) on $(DEPLOY_HOST)"

# --- Test database (podman) and test targets ----------------------------------

PODMAN       ?= podman
DB_IMAGE     ?= agrammon-db
DB_CONTAINER ?= agrammon-postgres
DB_PORT      ?= 55432

.PHONY: db-build db-start db-stop db-restart db-logs db-psql test unit-test

db-build:
	$(PODMAN) build -t $(DB_IMAGE) t/

db-start: db-build
	$(PODMAN) run -d -p $(DB_PORT):5432 --name $(DB_CONTAINER) --replace $(DB_IMAGE)
	@echo "Waiting for DB to accept connections..."
	@for i in $$(seq 1 30); do \
	    if $(PODMAN) exec $(DB_CONTAINER) pg_isready -U postgres -d agrammon_test >/dev/null 2>&1; then \
	        echo "DB ready on localhost:$(DB_PORT)"; exit 0; \
	    fi; \
	    sleep 1; \
	done; \
	echo "DB did not become ready in 30s; recent container logs:"; \
	$(PODMAN) logs --tail 50 $(DB_CONTAINER); \
	exit 1

db-stop:
	-$(PODMAN) stop $(DB_CONTAINER)
	-$(PODMAN) rm $(DB_CONTAINER)

db-restart: db-stop db-start

db-logs:
	$(PODMAN) logs $(DB_CONTAINER)

db-psql:
	psql -h localhost -p $(DB_PORT) -U agrammon -d agrammon_test

# Run the full suite (DB-backed integration tests included).
# Caller must ensure the test DB is running (e.g. `make db-start`).
test:
	AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml prove6 -l t/

# Skip DB-backed tests (those that honor AGRAMMON_UNIT_TEST=1).
unit-test:
	AGRAMMON_UNIT_TEST=1 prove6 -l t/

# --- Local development database (podman, persistent) --------------------------
#
# Reuses the test image (built via $(DB_IMAGE)) but runs a separate container
# on a different port with a bind-mounted data directory so datasets survive
# container restarts. Setting AGRAMMON_DEV_PASSWORD on first start gives the
# seeded admin user (test@agrammon.ch) a working password for web UI login.
#
# Schema/seed scripts only run on the FIRST start (when DEV_DB_DATA is empty).
# To pick up schema changes, run `make dev-db-reset`.

DEV_DB_CONTAINER ?= agrammon-dev-db
DEV_DB_PORT      ?= 55433
DEV_DB_DATA      ?= $(abs_top_builddir)/dev/db-data
DEV_DB_PASSWORD  ?= agrammon

.PHONY: dev-db-start dev-db-stop dev-db-restart dev-db-logs dev-db-psql dev-db-reset

dev-db-start: db-build
	@mkdir -p $(DEV_DB_DATA)
	$(PODMAN) run -d \
	    -p $(DEV_DB_PORT):5432 \
	    --name $(DEV_DB_CONTAINER) --replace \
	    -e AGRAMMON_DEV_PASSWORD=$(DEV_DB_PASSWORD) \
	    -v $(DEV_DB_DATA):/var/lib/postgresql/data:Z \
	    $(DB_IMAGE)
	@echo "Waiting for dev DB to accept connections..."
	@for i in $$(seq 1 30); do \
	    if $(PODMAN) exec $(DEV_DB_CONTAINER) pg_isready -U postgres -d agrammon_test >/dev/null 2>&1; then \
	        echo "Dev DB ready on localhost:$(DEV_DB_PORT) (login: test@agrammon.ch / $(DEV_DB_PASSWORD))"; \
	        exit 0; \
	    fi; \
	    sleep 1; \
	done; \
	echo "Dev DB did not become ready in 30s; recent container logs:"; \
	$(PODMAN) logs --tail 50 $(DEV_DB_CONTAINER); \
	exit 1

dev-db-stop:
	-$(PODMAN) stop $(DEV_DB_CONTAINER)
	-$(PODMAN) rm $(DEV_DB_CONTAINER)

dev-db-restart: dev-db-stop dev-db-start

dev-db-logs:
	$(PODMAN) logs $(DEV_DB_CONTAINER)

dev-db-psql:
	psql -h localhost -p $(DEV_DB_PORT) -U agrammon -d agrammon_test

# Wipe the bind-mounted data directory so the next start re-runs init scripts.
# Refuses to delete unless DEV_DB_DATA looks like a project-relative path, to
# avoid wiping an unintended directory if someone overrides DEV_DB_DATA.
dev-db-reset: dev-db-stop
	@case "$(DEV_DB_DATA)" in \
	    */dev/db-data) rm -rf $(DEV_DB_DATA); echo "Wiped $(DEV_DB_DATA)";; \
	    *) echo "Refusing to wipe DEV_DB_DATA=$(DEV_DB_DATA): not a */dev/db-data path"; exit 1;; \
	esac

# --- Container image (multi-stage Dockerfile → harbor.oetiker.ch) --------------
#
# Tag convention: <env>-<version>.  Customer overlay
# (oep-k8s/customers/oep/services/agrammon/values.yaml) picks images.test.tag
# or images.prod.tag depending on per-instance `env:`.
#
# Override on the command line, e.g.:
#   make image-push CONTAINER_VERSION=2026.05.20 CONTAINER_ENV=prod
#   make image      CONTAINER_BUILD_ARGS="--build-arg TYPST_VERSION=0.14.3"
#
# Login (one-time per session) before pushing:
#   podman login harbor.oetiker.ch

CONTAINER_REGISTRY ?= harbor.oetiker.ch
CONTAINER_PROJECT  ?= agrammon
CONTAINER_IMAGE    ?= $(CONTAINER_REGISTRY)/$(CONTAINER_PROJECT)/model
CONTAINER_VERSION  ?= $(shell cat VERSION 2>/dev/null || echo dev)
CONTAINER_ENV      ?= test
CONTAINER_TAG      ?= $(CONTAINER_ENV)-$(CONTAINER_VERSION)
CONTAINER_BUILD_ARGS ?=

.PHONY: image image-push image-test image-prod image-print

image-print:
	@echo "Image:    $(CONTAINER_IMAGE):$(CONTAINER_TAG)"
	@echo "Registry: $(CONTAINER_REGISTRY)  (project: $(CONTAINER_PROJECT))"
	@echo "Env:      $(CONTAINER_ENV)"
	@echo "Version:  $(CONTAINER_VERSION)  (from VERSION file or 'dev' fallback)"
	@echo ""
	@echo "Build args: $(CONTAINER_BUILD_ARGS)"

image:
	$(PODMAN) build $(CONTAINER_BUILD_ARGS) -f Dockerfile -t $(CONTAINER_IMAGE):$(CONTAINER_TAG) .

# Push depends on image — rebuilds if Dockerfile/COPY targets changed; podman
# layer cache makes subsequent pushes fast when nothing changed.
image-push: image
	@echo "Pushing $(CONTAINER_IMAGE):$(CONTAINER_TAG) ..."
	@echo "(Run 'podman login $(CONTAINER_REGISTRY)' first if you haven't.)"
	$(PODMAN) push $(CONTAINER_IMAGE):$(CONTAINER_TAG)

image-test:
	$(MAKE) image-push CONTAINER_ENV=test

image-prod:
	$(MAKE) image-push CONTAINER_ENV=prod
