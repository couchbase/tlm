# PLEASE NOTE: This Makefile is provided as a convenience for those
# who do not wish to interact with CMake. It is NOT SUPPORTED by the
# Couchbase build team, and the production builds do NOT make use of
# it, so bugs filed against it will need to be handled by those devs
# who care to use it.

PREFIX:=$(shell pwd)/install
MAKEFLAGS=--no-print-directory

PASSTHRU_TARGETS=all analyze clean clean-all clean-xfd clean-xfd-hard \
  e2etest e2eviewtests geocouch-build-for-testing install reset run-mats test

$(PASSTHRU_TARGETS):
	@$(MAKE) -f Makefile \
            MAKETYPE="Unix Makefiles" \
            PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp \
            SEPARATOR=/ RM=rm RMOPTS=-rf $@

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
