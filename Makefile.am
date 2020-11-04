#  Copyright (C) 2020 Fritz Zaucker

AUTOMAKE_OPTIONS = foreign

SUBDIRS = etc frontend

PUB := $(shell find -L public -type d \( -name ".??*" -o -name transpiled \) -prune -o -not -name "*db.json" -a -not -name "*.map" -a -not -name "*~" -a -not -name transpiled -a -not -name "*.tmp"  -a -type f -print )
SHARE := $(shell test -d share && find -L share -type d -name ".??*" -prune -o -not -name ".*" -a -not -name "*~" -a -not -name "*.tmp" -a -not -name '*.sql' -a -not -wholename '*/Docu/*' -a -not -wholename '*/Docu' -a -not -wholename '*/_Attic' -a -not -wholename '*/_Attic/*' -a -type f -print)

PERLTESTS := $(shell find -L t -name "*.t")
PM := $(shell find -L lib -name "*.pm")

#EXTRA_DIST = META6.json COPYRIGHT LICENSE CHANGES AUTHORS bootstrap $(PUB) $(POD) $(TEMPL) $(SHARE)

EXTRA_DIST = META6.json COPYRIGHT bin lib/Agrammon bootstrap $(PUB) $(SHARE) # $(PERLTESTS)

YEAR := $(shell date +%Y)
DATE := $(shell date +%Y-%m-%d)

datadir = $(prefix)
nobase_data_DATA = $(PUB) $(TEMPL) $(SHARE)

README.md COPYRIGHT:
	$(PERL) -i -p -e 's/(#VERSION#|\d+\.\d+\.\d+[^.\s]*)/$(PACKAGE_VERSION)/g;s/(#YEAR#|20[1-9]\d)/$(YEAR)/g;s/(#DATE#|20[1-9]\d-[01]\d-[0-3]\d)/$(DATE)/g;' $@


LANGUAGES := $(shell  $(PERL) -e 'use JSON::PP qw(decode_json); print join(" ", map {"share/".$$_.".po"} @{decode_json(join("",<>))->{locales}})' frontend/compile.json)

test:
	prove -j8 -e 'raku -Ilib' t

unit-test:
	AGRAMMON_UNIT_TEST=1 prove -j8 -e 'raku -Ilib' t
