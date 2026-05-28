
AUTOMAKE_OPTIONS=foreign

EXTRA_DIST = compile.json Manifest.json package.json pnpm-lock.yaml .npmrc $(shell find source -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp" -a -not -name "Makefile*" -a -type f -print )

# Translation sources compiled into the Qooxdoo bundle. Listed explicitly
# as build prerequisites so that editing a .po file retriggers a rebuild
# ($(CBFILES) used previously was never defined and expanded to nothing).
PO_FILES = $(wildcard source/translation/*.po)

if BUILD_QOOXDOO_APP

all-local: build

.PHONY: source source-watch node_modules build clean update-po

node_modules: node_modules/.installed

source: node_modules compiled/source/.built


source-watch: node_modules
	$(PNPM) exec qx compile --watch --feedback=false --erase

build: ../public/.built

# Extract translatable strings into the .po files and normalise their
# "#:" location comments (see tools/po-locations.pl). This is the ONLY
# target that writes to source/translation/*.po — ordinary builds compile
# the existing .po read-only, so deploys never mutate tracked sources.
# Run it after adding/removing tr() strings, then commit the .po changes.
update-po: node_modules
	$(PNPM) exec qx compile --update-po-files --feedback=false
	$(PERL) $(srcdir)/tools/po-locations.pl $(srcdir)/source/translation/*.po

dist-hook:
	$(PERL) -i -p -e 's/#VERSION#/$(PACKAGE_VERSION)/g;s/#YEAR#/$(YEAR)/g;s/#DATE#/$(DATE)/g;' $(distdir)/../public/$(QX_CLASS)/*.js

clean: node_modules
	$(PNPM) exec qx clean

../public/.built: $(EXTRA_DIST) Makefile.in $(PO_FILES)
	$(MAKE) node_modules
	$(PNPM) exec qx compile --target=build --feedback=false --erase
	mkdir -p ../public/$(QX_CLASS)
	cp -p compiled/build/$(QX_CLASS)/*.js ../public/$(QX_CLASS)
	cp -p compiled/build/$(QX_CLASS)/*.js.map ../public/$(QX_CLASS)
	cp -p compiled/build/index.html ../public
	cp -pa compiled/build/resource ../public
	touch $@

compiled/source/.built: $(EXTRA_DIST) Makefile.in $(PO_FILES)
	$(PNPM) exec qx compile --feedback=false
	touch $@

node_modules/.installed pnpm-lock.yaml: package.json
	$(PNPM) install
	touch node_modules/.installed
endif
