# -*- Mode: makefile -*-
TOPDIR := $(shell pwd)
PREFIX := $(TOPDIR)/install

COMPONENTS := $(COMPONENTS_EXTRA) \
        bucket_engine \
	couchstore \
	ep-engine \
	libconflate \
	libmemcached \
	libvbucket \
	membase-cli \
	memcached \
	moxi \
	couchdb \
        couchbase-python-client \
	couchbase-examples \
	ns_server

ifneq "$(DESTDIR)" ""
LDFLAGS := -L$(DESTDIR)$(PREFIX)/lib $(LDFLAGS)
CPPFLAGS := -I$(DESTDIR)$(PREFIX)/include $(CPPFLAGS)
export LDFLAGS CPPFLAGS
endif

ifneq "$(COUCHBASE_DEBUG_BUILD)" ""
WITH_DEBUG_FLAG=--with-debug
endif

ifneq "$(realpath portsigar/configure.ac)" ""
COMPONENTS += sigar portsigar
BUILD_SIGAR := 1
endif

ifdef FOR_WINDOWS
COMPONENTS := $(filter-out libcouchbase, $(COMPONENTS))
endif

BUILD_COMPONENTS := $(filter-out ns_server, $(COMPONENTS))
BUILD_COMPONENTS_EX := geocouch

MAKE_INSTALL_TARGETS := $(patsubst %, make-install-%, $(BUILD_COMPONENTS))
MAKE_INSTALL_TARGETS_EX := $(patsubst %, make-install-%, $(BUILD_COMPONENTS_EX))

TEST_COMPONENTS := $(filter-out libconflate membase-cli moxi, $(BUILD_COMPONENTS))
MAKE_TEST_TARGETS := $(patsubst %, make-test-%, $(TEST_COMPONENTS))
MAKE_TEST_TARGETS_EX :=

MAKEFILE_TARGETS := $(patsubst %, %/Makefile, $(BUILD_COMPONENTS))

OPTIONS := --prefix=$(PREFIX)
AUTOGEN := ./config/autorun.sh

ifdef PREFER_STATIC
LIBRARY_OPTIONS := --enable-static --disable-shared
else
NUKE_LA_FILES ?= false
LIBRARY_OPTIONS := --disable-static --enable-shared
endif

all: do-install-all

DIST_VERSION = `git describe`
DIST_MANIFEST = manifest.xml
DIST_PRODUCT = couchbase-server
DIST_COMPONENTS_EXTRA = couchbase-python-client geocouch
DIST_COMPONENTS = $(filter-out libcouchbase, $(COMPONENTS)) $(DIST_COMPONENTS_EXTRA)

dist:
	for i in $(DIST_COMPONENTS); do (cd $$i && rm -f *.tar.gz && make dist || true); done
	mkdir -p tmp/$(DIST_PRODUCT)_src
	rm -rf tmp/$(DIST_PRODUCT)_src/*
	(for i in $(DIST_COMPONENTS); do \
         mkdir -p tmp/$(DIST_PRODUCT)_src/$$i; \
         (cd tmp/$(DIST_PRODUCT)_src/$$i && \
          tar --strip-components 1 -xzf ../../../$$i/$$i-*.tar.gz || \
          tar --strip-components 1 -xzf ../../../$$i/*.tar.gz || \
          (cd ../.. && rm -rf $(DIST_PRODUCT)_src/$$i)); \
         done)
	cp Makefile tmp/$(DIST_PRODUCT)_src
	if [ -f $(DIST_MANIFEST) ]; then cp $(DIST_MANIFEST) tmp/$(DIST_PRODUCT)_src/manifest.xml; fi
	tar -C tmp -czf $(DIST_PRODUCT)_src-$(DIST_VERSION).tar.gz $(DIST_PRODUCT)_src

test: $(MAKE_TEST_TARGETS) $(MAKE_TEST_TARGETS_EX)

e2etest:
	cd testrunner && $(MAKE) test

e2eviewtests:
	cd testrunner && $(MAKE) test-views

ifdef BUILD_SIGAR
deps-for-portsigar: make-install-sigar
portsigar/Makefile: AUTOGEN := ./bootstrap
portsigar/Makefile: CONFIGURE_PREFIX := LDFLAGS="-L$(PREFIX)/lib $(LDFLAGS)"
sigar/Makefile: AUTOGEN := ./autogen.sh
portsigar_EXTRA_MAKE_OPTIONS := 'CPPFLAGS=-I$(TOPDIR)/sigar/include $(CPPFLAGS)'
sigar_OPTIONS := $(LIBRARY_OPTIONS) $(sigar_OPTIONS)
endif

do-install-all: $(MAKE_INSTALL_TARGETS) $(MAKE_INSTALL_TARGETS_EX) make-install-ns_server

-clean-common:
	rm -rf install tmp
	rm -f moxi*log
	rm -f memcached*log

clean: -clean-common
	for i in $(COMPONENTS); do (cd $$i && make clean || true); done

distclean: -clean-common
	for i in $(COMPONENTS); do (cd $$i && make distclean || true); done
	rm -rf install tmp
	rm -f moxi*log
	rm -f memcached*log

clean-xfd: $(patsubst %, do-clean-xfd-%, $(COMPONENTS) $(BUILD_COMPONENTS_EX)) -clean-common
	(cd icu4c && git clean -Xfdq) || true

clean-xfd-hard: $(patsubst %, do-hard-clean-xfd-%, $(COMPONENTS) $(BUILD_COMPONENTS_EX)) -clean-common
	(cd icu4c && git clean -xfd) || true

do-clean-xfd-%:
	(cd $* && git clean -Xfdq)

do-hard-clean-xfd-%:
	(cd $* && git clean -xfdq)

CONFIGURE_TARGETS := $(patsubst %, %/configure, $(BUILD_COMPONENTS))

ifdef AUTO_RECONFIG

define define-configure-target-deps
$(1)/configure: $(1)/.git/HEAD $(1)/.git/$(shell git --git-dir=$(1)/.git symbolic-ref -q HEAD || echo HEAD)
endef
# $(foreach comp, $(BUILD_COMPONENTS),$(eval $(info $(call define-configure-target-deps,$(comp)))))
# $(error stop)
$(foreach comp, $(BUILD_COMPONENTS),$(eval $(call define-configure-target-deps,$(comp))))

endif

$(CONFIGURE_TARGETS):
	cd $(dir $@) && $(AUTOGEN_PREFIX) $(AUTOGEN)

$(MAKEFILE_TARGETS): %/Makefile: | %/configure deps-for-%
	cd $* && $(CONFIGURE_PREFIX) ./configure -C $(OPTIONS) $($*_OPTIONS) $($*_EXTRA_OPTIONS)

$(MAKE_INSTALL_TARGETS): make-install-%: %/Makefile deps-for-%
	(rm -rf tmp/$*; mkdir -p tmp/$*)
	$(MAKE) -C $* install $($*_EXTRA_MAKE_OPTIONS)
	if [ "x$(NUKE_LA_FILES)" = "xtrue" ]; then $(RM) -f $(DESTDIR)$(PREFIX)/lib/*.la; fi

$(MAKE_TEST_TARGETS): make-test-%: make-install-%
	$(MAKE) -C $* test

$(patsubst %, deps-for-%, $(BUILD_COMPONENTS)):

libmemcached_OPTIONS := $(LIBRARY_OPTIONS) --disable-dtrace --without-docs --disable-sasl --without-memcached
ifndef CROSS_COMPILING
deps-for-libmemcached: make-install-memcached
endif

ifdef USE_TCMALLOC
libmemcached_OPTIONS += --enable-tcmalloc
endif

# tar.gz _should_ have ./configure inside, but it doesn't
# make-install-libmemcached: AUTOGEN := true

libvbucket_OPTIONS :=  $(LIBRARY_OPTIONS) --without-docs $(WITH_DEBUG_FLAG)

libcouchbase_OPTIONS :=  $(LIBRARY_OPTIONS) $(WITH_DEBUG_FLAG)
libcouchbase_EXTRA_OPTIONS := 'LDFLAGS=-L$(DESTDIR)$(PREFIX)/lib $(LDFLAGS)' \
                              'CPPFLAGS=-I$(DESTDIR)$(PREFIX)/include $(CPPFLAGS)'
deps-for-libcouchbase: make-install-libvbucket make-install-memcached

ep-engine_OPTIONS := $(WITH_DEBUG_FLAG) \
                     'LDFLAGS=-L$(DESTDIR)$(PREFIX)/lib $(LDFLAGS)' \
                     'CPPFLAGS=-I$(DESTDIR)$(PREFIX)/include $(CPPFLAGS)'
deps-for-ep-engine: make-install-memcached make-install-couchstore

couchstore_OPTIONS := $(LIBRARY_OPTIONS) $(WITH_DEBUG_FLAG)

bucket_engine_OPTIONS := $(WITH_DEBUG_FLAG) \
                         'CPPFLAGS=-I$(DESTDIR)$(PREFIX)/include $(CPPFLAGS)'
deps-for-bucket_engine: make-install-memcached make-install-ep-engine

moxi_OPTIONS := --enable-moxi-libvbucket \
	--enable-moxi-libmemcached \
	--without-check
moxi_EXTRA_MAKE_OPTIONS := 'CPPFLAGS=-I$(TOPDIR)/libmemcached -I$(TOPDIR)/libvbucket/include -I$(PREFIX)/include $(CPPFLAGS)'
ifndef CROSS_COMPILING
moxi_OPTIONS += --with-memcached=$(DESTDIR)$(PREFIX)/bin/memcached
endif
deps-for-moxi: make-install-libconflate make-install-libvbucket make-install-libmemcached make-install-memcached

libconflate_OPTIONS := $(LIBRARY_OPTIONS) --without-check $(WITH_DEBUG_FLAG)

memcached_OPTIONS := --enable-isasl

make-install-ns_server: make-install-geocouch
	cd ns_server && ./configure "--prefix=$(PREFIX)"
	$(MAKE) -C ns_server install "PREFIX=$(PREFIX)"

make-install-geocouch:
	$(MAKE) -C geocouch COUCH_SRC=../couchdb/src/couchdb
	mkdir -p $(DESTDIR)$(PREFIX)/lib/couchdb/plugins/geocouch/ebin
	cp -r geocouch/ebin/* $(DESTDIR)$(PREFIX)/lib/couchdb/plugins/geocouch/ebin
	mkdir -p $(DESTDIR)$(PREFIX)/etc/couchdb/default.d
	cp -r geocouch/etc/couchdb/default.d/* $(DESTDIR)$(PREFIX)/etc/couchdb/default.d
	mkdir -p $(DESTDIR)$(PREFIX)/share/couchdb/www/script/test
	cp -r geocouch/share/www/script/test/* $(DESTDIR)$(PREFIX)/share/couchdb/www/script/test

ifdef PLEASE_BUILD_COUCH_DEPS
couchdb_OPTIONS := --with-v8-lib=$(PREFIX)/lib --with-v8-include=$(PREFIX)/include "PATH=$(PREFIX)/bin:$(PATH)"

# it's necessary to pass this late. couchdb is using libtool and
# libtool portably understands -rpath (NOTE: _single_ dash). Passing
# it to configure fails, because a bunch of stuff is checked with
# plain gcc versus with libtool wrapper.
# NOTE: this doesn't work on Darwin and has issues on Solaris
couchdb_EXTRA_MAKE_OPTIONS := "LDFLAGS=-R $(PREFIX)/lib $(LDFLAGS)"
endif

couchdb/Makefile: AUTOGEN = ./bootstrap

ifdef PLEASE_BUILD_COUCH_DEPS
deps-for-couchdb: make-install-couchdb-deps
endif

WRAPPERS := $(patsubst %, $(PREFIX)/bin/%, memcached-wrapper moxi-wrapper)

$(WRAPPERS): $(PREFIX)/bin/%: tlm/%.in
	mkdir -p $(PREFIX)/bin
	sed -e 's|@PREFIX@|$(PREFIX)|g' <$< >$@ || (rm $@ && false)
	chmod +x $@

WIN32_MAKE_TARGET := do-install-all
WIN32_HOST := i586-mingw32msvc
WIN_CYGWIN_FLAGS := CC=i686-pc-cygwin-gcc CXX=i686-pc-cygwin-g++

win32-cross:
	$(MAKE) $(WIN32_MAKE_TARGET) FOR_WINDOWS=1 HOST=$(WIN32_HOST) CROSS_COMPILING=1

ifdef FOR_WINDOWS

WIN_FLAGS := 'LOCAL=$(PREFIX)'

ifndef LIBS_PREFIX
$(warning LIBS_PREFIX usually needs to be given so that I can find libcurl, libevent and libpthread)
else

OPTIONS += 'CFLAGS=-I$(LIBS_PREFIX)/include $(CFLAGS)' 'LDFLAGS=-L$(LIBS_PREFIX)/lib $(LDFLAGS)'
LOCALINC := -I${PREFIX}/include
LOCALINC += -I$(LIBS_PREFIX)/include
ifdef NO_USECONDS_T
LOCALINC += -Duseconds_t=unsigned
endif

WIN_FLAGS += 'LOCALINC=$(LOCALINC)' 'LIB=-L$(LIBS_PREFIX)/lib $(LIB)'

couchstore_OPTIONS += --enable-shared --enable-static
endif

ifdef HOST
OPTIONS := --host=$(HOST) $(OPTIONS)
WIN_FLAGS += CC=$(HOST)-gcc CXX=$(HOST)-g++
endif

libmemcached_OPTIONS += --without-memcached
moxi_OPTIONS += --without-memcached

memcached/Makefile:
	touch $@

ep-engine/Makefile:
	touch $@

bucket_engine/Makefile:
	touch $@

memcached/configure ep-engine/configure bucket_engine/configure:
	@true

membase-cli/Makefile:
	touch $@

make-install-membase-cli:
	(cd membase-cli && mkdir -p $(PREFIX)/bin/simplejson && \
	cp couchbase-cli cbbackup cbrestore cbtransfer cbclusterstats cbworkloadgen *.py LICENSE $(PREFIX)/bin && \
	cp simplejson/LICENSE.txt simplejson/*.py $(PREFIX)/bin/simplejson)

couchbase-examples/Makefile:
	touch $@

make-install-couchbase-examples: install-couchbase-python-client
	(cp couchbase-examples/cbdocloader $(PREFIX)/bin && \
	 mkdir -p $(PREFIX)/samples && \
	 cp couchbase-examples/*.zip $(PREFIX)/samples)

install-couchbase-python-client:
	cd couchbase-python-client && mkdir -p $(PREFIX)/bin/couchbase && \
	cp -r couchbase httplib2 simplejson uuid.py $(PREFIX)/bin

make-install-memcached:
	(cd memcached && $(MAKE) -f win32/Makefile.mingw $(WIN_FLAGS) all \
         && mkdir -p $(PREFIX)/lib/memcached \
         && cp .libs/*.so $(PREFIX)/lib/memcached \
         && cp memcached.exe mcstat.exe $(PREFIX)/bin)

# hey, it's almost like Lisp
EP_ENGINE_MARCH := $(strip $(if $(or $(findstring x86_64, $(HOST)), $(findstring amd64, $(HOST))), ,-march=i686))

make-install-ep-engine:
	chmod +x ep-engine/win32/config.sh
	(cd ep-engine && \
            $(MAKE) -f win32/Makefile.genconf $(WIN_CYGWIN_FLAGS) && \
            $(MAKE) -f win32/Makefile.gencode $(WIN_CYGWIN_FLAGS) && \
            $(MAKE) -f win32/Makefile.mingw "MARCH=$(EP_ENGINE_MARCH)" $(WIN_FLAGS) install)

make-install-bucket_engine:
	(cd bucket_engine && $(MAKE) -f win32/Makefile.mingw $(WIN_FLAGS) all \
	 && cp .libs/bucket_engine.so "$(PREFIX)/lib/memcached")

libmemcached/Makefile: fix-broken-libmemcached-tests

fix-broken-libmemcached-tests:
	patch -p1 -N -r /dev/null -t -d libmemcached <tlm/libmemcached-win32-fix.diff  || (echo "probably patched"; patch -v >/dev/null 2>&1)

endif

AUTOCONF213 := autoconf213

icu4c/source/Makefile:
	(cd icu4c/source && ./configure "--prefix=$(PREFIX)")

make-install-icu4c: icu4c/source/Makefile
	$(MAKE) -C icu4c/source install

make-install-couchdb-deps: make-install-icu4c

CHECK_COMPONENTS ?= $(COMPONENTS)

CHECK_TARGETS := $(patsubst %, check-%, $(CHECK_COMPONENTS))

MAKE_CHECK_TARGET := check

check-fast: check-ns_server check-bucket_engine check-ep-engine check-ns_server check-libvbucket check-couchdb

check: $(CHECK_TARGETS)

check-memcached check-moxi check-bucket_engine check-ns_server: MAKE_CHECK_TARGET := test

$(CHECK_TARGETS): check-%: make-install-%
	$(MAKE) -C $* $(MAKE_CHECK_TARGET)

replace-wrappers: $(WRAPPERS) all
	mv $(PREFIX)/bin/memcached $(PREFIX)/bin/memcached.orig
	mv $(PREFIX)/bin/moxi $(PREFIX)/bin/moxi.orig
	sed -e 's|/bin/memcached|/bin/memcached.orig|g' <$(PREFIX)/bin/memcached-wrapper >$(PREFIX)/bin/memcached
	sed -e 's|/bin/moxi|/bin/moxi.orig|g' <$(PREFIX)/bin/moxi-wrapper >$(PREFIX)/bin/moxi
	chmod +x $(PREFIX)/bin/memcached $(PREFIX)/bin/moxi

ifneq "$(realpath tlm/Makefile.top)" ""
Makefile: tlm/Makefile.top
	rm -f $@
	cp $< $@
endif

# Allow the user to override stuff for all projects (like
# --with-erlang=)
ifneq "$(realpath $(HOME)/.couchbase/build/Makefile.extra)" ""
include $(HOME)/.couchbase/build/Makefile.extra
endif

# this thing can override settings and add components
ifneq "$(realpath .repo/Makefile.extra)" ""
include .repo/Makefile.extra
endif
