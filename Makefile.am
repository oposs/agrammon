#  Copyright (C) 2023 Fritz Zaucker

AUTOMAKE_OPTIONS =  foreign

SUBDIRS = thirdparty etc frontend lib bin

PUB := $(shell find -L public -type d \( -name ".??*" -o -name transpiled \) -prune -o -not -name "*db.json" -a -not -name "*.map" -a -not -name "*~" -a -not -name transpiled -a -not -name "*.tmp"  -a -type f -print )

TEMPL := $(shell test -d templates && find -L templates -type f -name "*.ep")
SHARE := $(shell test -d share && find -L share -type d -name ".??*" -prune -o -not -name ".*" -a -not -name "*~" -a -not -wholename "*/Docu/*" -a -not -name "*.tmp"  -a -type f -print)

PERLTESTS := $(shell find t -name "*.t")
PM := $(shell find lib -name "*.pm")

EXTRA_DIST = VERSION cpanfile COPYRIGHT CHANGELOG.md README.md bootstrap $(PUB) $(wildcard t/*.t) $(POD) $(TEMPL) $(PERLTESTS) $(SHARE) META6.json

datadir = $(prefix)
nobase_data_DATA = $(PUB) $(TEMPL) $(SHARE)

VERSION:
	jq '.version' < META6.json | tr -d '"\n' > VERSION
