#  Copyright (C) 2023 Fritz Zaucker

AUTOMAKE_OPTIONS =  foreign

# SUBDIRS = thirdparty etc frontend
SUBDIRS = frontend Inline

PUB := $(shell find -L public -type d \( -name ".??*" -o -name transpiled \) -prune -o -not -name "*db.json" -a -not -name "*.map" -a -not -name "*~" -a -not -name transpiled -a -not -name "*.tmp"  -a -type f -print )

TEMPL := $(shell test -d templates && find -L templates -type f -name "*.ep")
SHARE := $(shell test -d share && find -L share -type d -name ".??*" -prune -o -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp"  -a -not -path "share/Models/Experimental/*" -a -type f -print)

PERLTESTS := $(shell find t -name "*.t")
PM := $(shell find lib -name "*.pm")

# EXTRA_DIST = VERSION cpanfile COPYRIGHT LICENSE CHANGELOG AUTHORS bootstrap $(PUB) $(wildcard t/*.t) $(POD) $(TEMPL) $(PERLTESTS) $(SHARE) Dockerfile

EXTRA_DIST = META6.json README.md VERSION cpanfile COPYRIGHT CHANGELOG.md bootstrap $(PUB) $(wildcard t/*.t) $(POD) $(TEMPL) $(PERLTESTS) $(SHARE) bin lib

deps:
		zef --debug --/test --deps-only --test-depends install .
		cpanm --installdeps .

deploy:
	scp agrammon-`cat VERSION`.tar.gz agrammon@web-volki-01-adm:src/
	ssh camas@web-volki-01-adm mkdir opt/releases/agrammon-`cat VERSION` && cd opt/releases/agrammon-`cat VERSION` && tar zxf $HOME/src/agrammon-`cat VERSION`

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
	PERL5LIB=Inline/perl5 AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml prove6 -l t/

# Skip DB-backed tests (those that honor AGRAMMON_UNIT_TEST=1).
unit-test:
	AGRAMMON_UNIT_TEST=1 prove6 -l t/
