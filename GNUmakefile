# PLEASE NOTE: This Makefile is provided as a convenience for those
# who do not wish to interact with CMake. It is NOT SUPPORTED by the
# Couchbase build team, and the production builds do NOT make use of
# it, so bugs filed against it will need to be handled by those devs
# who care to use it.

ROOT:=$(CURDIR)
PREFIX:=$(ROOT)/install
MAKEFLAGS=--no-print-directory

PASSTHRU_TARGETS=all analytics-install analyze clean clean-all clean-xfd clean-xfd-hard \
  e2etest e2eviewtests geocouch-build-for-testing go-mod-tidy install reset run-mats \
  test unset-version build/Makefile

$(PASSTHRU_TARGETS):
	@$(MAKE) -f Makefile \
            MAKETYPE="Unix Makefiles" \
            PREFIX="$(PREFIX)" CHMODCMD="chmod u+w" CP=cp \
            SEPARATOR=/ RM=rm RMOPTS=-rf $@

DEPS_DIR := $(ROOT)/tlm/deps/packages

# it's a little wasteful to call cmake all the time, but the code path taken
# there might depend on the presence/absence of downloaded dependencies
.PHONY: build_deps deps-all
build_deps:
	mkdir -p build_deps
	(cd build_deps && cmake $(DEPS_DIR))

dep-%: build_deps
	$(MAKE) -C "build_deps" $(@:dep-%=build-and-cache-%)

deps-all: build_deps
	$(MAKE) -C "build_deps" build-and-cache-all
