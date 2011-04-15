# -*- Mode: makefile -*-
TOPDIR := $(shell pwd)
PREFIX := $(TOPDIR)/install

ifeq "$(realpath tlm/Makefile)" ""
$(error You need to be in top-level directory to use top-level makefile)
endif

COMPONENTS := bucket_engine \
	ep-engine \
	libconflate \
	libvbucket \
	libmemcached \
	membase-cli \
	memcached \
	memcachetest \
	moxi \
	ns_server \
	vbucketmigrator

ifneq "$(DESTDIR)" ""
LDFLAGS := -L$(DESTDIR)$(PREFIX)/lib $(LDFLAGS)
CPPFLAGS := -I$(DESTDIR)$(PREFIX)/include $(CPPFLAGS)
export LDFLAGS CPPFLAGS
endif

ifneq "$(realpath couchdb/configure.ac)" ""
BUILD_COUCH := 1
COMPONENTS += couchdb
endif

ifneq "$(realpath portsigar/configure.ac)" ""
COMPONENTS += sigar portsigar
BUILD_SIGAR := 1
endif

ifdef FOR_WINDOWS
COMPONENTS := $(filter-out couchdb memcachetest vbucketmigrator, $(COMPONENTS))
endif

BUILD_COMPONENTS := $(filter-out ns_server, $(COMPONENTS))

MAKE_INSTALL_TARGETS := $(patsubst %, make-install-%, $(BUILD_COMPONENTS))
MAKEFILE_TARGETS := $(patsubst %, %/Makefile, $(BUILD_COMPONENTS))

OPTIONS := --prefix=$(PREFIX)
AUTOGEN := ./config/autorun.sh

ifdef PREFER_STATIC
LIBRARY_OPTIONS := --enable-static --disable-shared
else
LIBRARY_OPTIONS := --disable-static --enable-shared
endif

all: do-install-all build-ns_server

ifdef BUILD_SIGAR
deps-for-portsigar: make-install-sigar
portsigar/Makefile: AUTOGEN := ./bootstrap
portsigar/Makefile: CONFIGURE_PREFIX := LDFLAGS="-L$(PREFIX)/lib $(LDFLAGS)"
sigar/Makefile: AUTOGEN := ./autogen.sh
portsigar_EXTRA_MAKE_OPTIONS := 'CPPFLAGS=-I$(TOPDIR)/sigar/include $(CPPFLAGS)'
endif

do-install-all: $(MAKE_INSTALL_TARGETS) make-install-ns_server

build-ns_server:
	$(MAKE) -C ns_server

-clean-common:
	rm -rf install tmp
	rm -f moxi*log
	rm -f memcached*log

clean: -clean-common
	for i in $(COMPONENTS); do (cd $$i && make clean || true); done

distclean: -clean-common
	for i in $(COMPONENTS); do (cd $$i && make distclean || true); done
	rm -rf install tmp
	rm moxi*log
	rm memcached*log

clean-xfd: $(patsubst %, do-clean-xfd-%, $(COMPONENTS)) -clean-common
	(cd icu4c && git clean -Xfd) || true
	(cd spidermonkey && git clean -Xfd) || true

clean-xfd-hard: $(patsubst %, do-hard-clean-xfd-%, $(COMPONENTS)) -clean-common
	(cd icu4c && git clean -xfd) || true
	(cd spidermonkey && git clean -xfd) || true

do-clean-xfd-%:
	(cd $* && git clean -Xfd)

do-hard-clean-xfd-%:
	(cd $* && git clean -xfd)

CONFIGURE_TARGETS := $(patsubst %, %/configure, $(BUILD_COMPONENTS))

$(CONFIGURE_TARGETS): %/configure:
	cd $* && $(AUTOGEN_PREFIX) $(AUTOGEN)

$(MAKEFILE_TARGETS): %/Makefile: | %/configure deps-for-%
	cd $* && $(CONFIGURE_PREFIX) ./configure $(OPTIONS) $($*_OPTIONS) $($*_EXTRA_OPTIONS)

$(MAKE_INSTALL_TARGETS): make-install-%: %/Makefile deps-for-%
	(rm -rf tmp/$*; mkdir -p tmp/$*)
	$(MAKE) -C $* install $($*_EXTRA_MAKE_OPTIONS)

$(patsubst %, deps-for-%, $(BUILD_COMPONENTS)):

libmemcached_OPTIONS := $(LIBRARY_OPTIONS) --disable-dtrace --without-docs
ifndef CROSS_COMPILING
libmemcached_OPTIONS += --with-memcached=$(DESTDIR)$(PREFIX)/bin/memcached
memcachetest_OPTIONS += --with-memcached=$(DESTDIR)$(PREFIX)/bin/memcached
deps-for-libmemcached: make-install-memcached
endif

ifdef USE_TCMALLOC
libmemcached_OPTIONS += --enable-tcmalloc
endif

# tar.gz _should_ have ./configure inside, but it doesn't
# make-install-libmemcached: AUTOGEN := true

libvbucket_OPTIONS :=  $(LIBRARY_OPTIONS) --without-docs --with-debug
libvbucket_EXTRA_MAKE_OPTIONS := 'CPPFLAGS=-I$(TOPDIR)/libmemcached $(CPPFLAGS)'
deps-for-libvbucket: make-install-libmemcached

memcachetest_EXTRA_MAKE_OPTIONS := 'CPPFLAGS=-I$(TOPDIR)/memcached/include -I$(TOPDIR)/libmemcached -I$(TOPDIR)/libvbucket/include $(CPPFLAGS)'
deps-for-memcachetest: make-install-memcached make-install-libmemcached make-install-libvbucket

ep-engine_OPTIONS := --with-memcached=../memcached --with-debug
ep-engine_EXTRA_MAKE_OPTIONS := 'CPPFLAGS=-I$(TOPDIR)/memcached/include $(CPPFLAGS)'
deps-for-ep-engine: make-install-memcached

bucket_engine_OPTIONS := --with-memcached=../memcached --with-debug
bucket-engine_EXTRA_MAKE_OPTIONS := 'CPPFLAGS=-I$(TOPDIR)/memcached/include $(CPPFLAGS)'
deps-for-bucket_engine: make-install-memcached

moxi_OPTIONS := --enable-moxi-libvbucket \
	--enable-moxi-libmemcached \
	--without-check
moxi_EXTRA_MAKE_OPTIONS := 'CPPFLAGS=-I$(TOPDIR)/libmemcached -I$(TOPDIR)/libvbucket/include -I$(PREFIX)/include $(CPPFLAGS)'
ifndef CROSS_COMPILING
moxi_OPTIONS += --with-memcached=$(DESTDIR)$(PREFIX)/bin/memcached
endif
deps-for-moxi: make-install-libconflate make-install-libvbucket make-install-libmemcached make-install-memcached

libconflate_OPTIONS := $(LIBRARY_OPTIONS) --without-check --with-debug

vbucketmigrator_OPTIONS := --without-sasl --with-isasl

memcached_OPTIONS := --enable-isasl

make-install-ns_server:
	cd ns_server && ./configure "--prefix=$(PREFIX)"
	$(MAKE) -C ns_server install "PREFIX=$(PREFIX)"

ifdef PLEASE_BUILD_COUCH_DEPS
couchdb_OPTIONS := --with-js-lib=$(PREFIX)/lib --with-js-include=$(PREFIX)/include "PATH=$(PREFIX)/bin:$(PATH)"

# it's necessary to pass this late. couchdb is using libtool and
# libtool portably understands -rpath (NOTE: _single_ dash). Passing
# it to configure fails, because a bunch of stuff is checked with
# plain gcc versus with libtool wrapper.
# NOTE: this doesn't work on Darwin and has issues on Solaris
couchdb_EXTRA_MAKE_OPTIONS := "LDFLAGS=-R $(PREFIX)/lib $(LDFLAGS)"
endif

ifdef BUILD_COUCH
couchdb/Makefile: AUTOGEN = ./bootstrap
endif

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
	(cd membase-cli && mkdir -p $(PREFIX)/bin/cli && \
	mkdir -p $(PREFIX)/bin/cli/simplejson && \
	cp membase *.py LICENSE $(PREFIX)/bin/cli && \
	cp simplejson/*.py $(PREFIX)/bin/cli/simplejson && \
	cp simplejson/LICENSE.txt $(PREFIX)/bin/cli/simplejson)

make-install-memcached:
	(cd memcached && $(MAKE) -f win32/Makefile.mingw $(WIN_FLAGS) all \
         && mkdir -p $(PREFIX)/lib/memcached \
         && cp .libs/*.so $(PREFIX)/lib/memcached \
         && cp memcached.exe mcstat.exe $(PREFIX)/bin)

# hey, it's almost like Lisp
EP_ENGINE_MARCH := $(strip $(if $(or $(findstring x86_64, $(HOST)), $(findstring amd64, $(HOST))), ,-march=i686))

make-install-ep-engine:
	chmod +x ep-engine/win32/config.sh
	(cd ep-engine && $(MAKE) -f win32/Makefile.mingw "MARCH=$(EP_ENGINE_MARCH)" $(WIN_FLAGS) install)

make-install-bucket_engine:
	(cd bucket_engine && $(MAKE) -f win32/Makefile.mingw $(WIN_FLAGS) all \
	 && cp .libs/bucket_engine.so "$(PREFIX)/lib/memcached")

libmemcached/Makefile: fix-broken-libmemcached-tests

fix-broken-libmemcached-tests:
	patch -p1 -N -r /dev/null -t -d libmemcached <tlm/libmemcached-win32-fix.diff  || true

endif

AUTOCONF213 := autoconf213

spidermonkey/configure:
	(cd spidermonkey && $(AUTOCONF213))

spidermonkey/Makefile: spidermonkey/configure
	(cd spidermonkey && ./configure "--prefix=$(PREFIX)" --without-x)

make-install-spidermonkey: spidermonkey/Makefile
	$(MAKE) -C spidermonkey
	$(MAKE) -C spidermonkey install

icu4c/source/Makefile:
	(cd icu4c/source && ./configure "--prefix=$(PREFIX)")

make-install-icu4c: icu4c/source/Makefile
	$(MAKE) -C icu4c/source install

make-install-couchdb-deps: make-install-spidermonkey make-install-icu4c

CHECK_COMPONENTS ?= $(COMPONENTS)

CHECK_TARGETS := $(patsubst %, check-%, $(CHECK_COMPONENTS))

MAKE_CHECK_TARGET := check

check-fast: check-ns_server check-bucket_engine check-ep-engine check-ns_server check-libvbucket check-couchdb

check: $(CHECK_TARGETS)

check-memcached check-moxi check-bucket_engine check-ns_server: MAKE_CHECK_TARGET := test

$(CHECK_TARGETS): check-%: make-install-%
	$(MAKE) -C $* $(MAKE_CHECK_TARGET)

replace-wrappers: $(WRAPPERS)
	test -f $(PREFIX)/bin/memcached.orig || mv $(PREFIX)/bin/memcached $(PREFIX)/bin/memcached.orig
	test -f $(PREFIX)/bin/moxi.orig || mv $(PREFIX)/bin/moxi $(PREFIX)/bin/moxi.orig
	sed -e 's|/bin/memcached|/bin/memcached.orig|g' <$(PREFIX)/bin/memcached-wrapper >$(PREFIX)/bin/memcached
	sed -e 's|/bin/moxi|/bin/moxi.orig|g' <$(PREFIX)/bin/moxi-wrapper >$(PREFIX)/bin/moxi
	chmod +x $(PREFIX)/bin/memcached $(PREFIX)/bin/moxi

# Allow the user to override stuff for all projects (like
# --with-erlang=)
ifneq "$(realpath $(HOME)/.couchbase/build/Makefile.extra)" ""
include $(HOME)/.couchbase/build/Makefile.extra
endif

# this thing can override settings and add components
ifneq "$(realpath .repo/Makefile.extra)" ""
include .repo/Makefile.extra
endif
