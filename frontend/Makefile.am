
AUTOMAKE_OPTIONS=foreign

EXTRA_DIST = compile.json Manifest.json package.json pnpm-lock.yaml .npmrc $(shell find source -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp" -a -not -name "Makefile*" -a -type f -print )

if BUILD_QOOXDOO_APP

all-local: build

.PHONY: source source-watch node_modules build clean

node_modules: node_modules/.installed

source: node_modules compiled/source/.built


source-watch: node_modules
	$(PNPM) exec qx compile --watch --feedback=false --erase --update-po-files

build: ../public/.built

dist-hook:
	$(PERL) -i -p -e 's/#VERSION#/$(PACKAGE_VERSION)/g;s/#YEAR#/$(YEAR)/g;s/#DATE#/$(DATE)/g;' $(distdir)/../public/$(QX_CLASS)/*.js

clean: node_modules
	$(PNPM) exec qx clean

../public/.built: $(EXTRA_DIST) Makefile.in $(CBFILES)
	$(MAKE) node_modules
	$(PNPM) exec qx compile --target=build --feedback=false --erase --update-po-files
	mkdir -p ../public/$(QX_CLASS)
	cp -p compiled/build/$(QX_CLASS)/*.js ../public/$(QX_CLASS)
	cp -p compiled/build/$(QX_CLASS)/*.js.map ../public/$(QX_CLASS)
	cp -p compiled/build/index.html ../public
	cp -pa compiled/build/resource ../public
	touch $@

compiled/source/.built: $(EXTRA_DIST) Makefile.in $(CBFILES)
	$(PNPM) exec qx compile --feedback=false --update-po-files
	touch $@

node_modules/.installed pnpm-lock.yaml: package.json
	$(PNPM) install
	touch node_modules/.installed
endif
