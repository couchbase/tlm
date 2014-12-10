PREFIX:=$(shell pwd)/install
MAKEFLAGS=--no-print-directory

all:
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp MAKETYPE="Unix Makefiles" all

install: all
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp MAKETYPE="Unix Makefiles" install

geocouch-build-for-testing:
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp MAKETYPE="Unix Makefiles" geocouch-build-for-testing

test:
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp MAKETYPE="Unix Makefiles" test

run-mats:
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp run-mats

e2etest:
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp e2etest

e2eviewtests:
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp e2eviewtests

analyze:
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp MAKETYPE="Unix Makefiles" $@

clean:
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp RM=rm RMOPTS=-rf SEPARATOR=/ clean

clean-xfd:
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp RM=rm RMOPTS=-rf SEPARATOR=/ clean-xfd

clean-xfd-hard: clean-xfd

clean-all: clean-xfd

ICU_OPT=
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
    # MB-11442
    ICU_OPT=-mmacosx-version-min=10.7
endif

icu4c/source/Makefile:
	(cd icu4c/source && \
	CFLAGS=$(ICU_OPT) CXXFLAGS=$(ICU_OPT) LDFLAGS=$(ICU_OPT) \
	  ./configure "--prefix=$(PREFIX)")

make-install-icu4c: icu4c/source/Makefile
	$(MAKE) -C icu4c/source install

make-install-couchdb-deps: make-install-icu4c
