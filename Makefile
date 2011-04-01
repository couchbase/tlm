# -*- Mode: makefile -*-
TOPDIR := $(shell pwd)
PREFIX := $(TOPDIR)/install

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

all: do-install-all dev-symlink build-ns_server

ifdef BUILD_SIGAR
deps-for-portsigar: make-install-sigar
portsigar/Makefile: AUTOGEN := ./bootstrap
portsigar/Makefile: CONFIGURE_PREFIX := LDFLAGS="-L$(PREFIX)/lib $(LDFLAGS)"
sigar/Makefile: AUTOGEN := ./autogen.sh
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

$(MAKEFILE_TARGETS): %/Makefile: | deps-for-%
	cd $* && $(AUTOGEN_PREFIX) $(AUTOGEN) && $(CONFIGURE_PREFIX) ./configure $(OPTIONS) $($*_OPTIONS) $($*_EXTRA_OPTIONS)

ifndef FUNKY_INSTALL

TSTAMP_TARGETS := $(patsubst %, tmp/installed-%, $(BUILD_COMPONENTS))

$(patsubst %, reinstall-%, $(BUILD_COMPONENTS)): reinstall-%: %/Makefile | deps-for-%
	$(MAKE) -C $* install
	mkdir -p tmp && touch tmp/installed-$*

REINSTALL_TSTAMPS := $(TSTAMP_TARGETS) tmp/installed-icu4c tmp/installed-spidermonkey

reinstall:
	rm -rf $(REINSTALL_TSTAMPS)
	$(MAKE) all

$(TSTAMP_TARGETS): tmp/installed-%: %/Makefile | deps-for-%
	$(MAKE) -C $* install $($*_EXTRA_MAKE_OPTIONS)
	mkdir -p tmp && touch $@

$(MAKE_INSTALL_TARGETS): make-install-%: tmp/installed-%

else

# TODO: this doesn't handle symlinks, disabled for now

$(MAKE_INSTALL_TARGETS): make-install-%: %/Makefile deps-for-%
	(rm -rf tmp/$*; mkdir -p tmp/$*)
	$(MAKE) -C $* install DESTDIR=$(TOPDIR)/tmp/$*
	cd $(TOPDIR)/tmp/$*; find . -type f -print | xargs -n1 -- bash -c 'diff -q "./$$1" "/$$1" >/dev/null 2>&1 || (mkdir -p `dirname "/$$1"` && cp -afl "./$$1" "/$$1")' --

endif


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
deps-for-libvbucket: make-install-libmemcached

deps-for-memcachetest: make-install-libmemcached make-install-libvbucket

ep-engine_OPTIONS := --with-memcached=../memcached --with-debug
deps-for-ep-engine: make-install-memcached

bucket_engine_OPTIONS := --with-memcached=../memcached --with-debug
deps-for-bucket_engine: make-install-memcached

moxi_OPTIONS := --enable-moxi-libvbucket \
	--enable-moxi-libmemcached \
	--without-check
ifndef CROSS_COMPILING
moxi_OPTIONS += --with-memcached=$(DESTDIR)$(PREFIX)/bin/memcached
endif
deps-for-moxi: make-install-libconflate make-install-libvbucket make-install-libmemcached make-install-memcached

libconflate_OPTIONS := $(LIBRARY_OPTIONS) --without-check --with-debug

vbucketmigrator_OPTIONS := --without-sasl --with-isasl

memcached_OPTIONS := --enable-isasl

make-install-ns_server:
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

dev-symlink: $(MAKE_INSTALL_TARGETS) $(WRAPPERS)
	mkdir -p ns_server/bin ns_server/lib/memcached
	ln -f -s $(TOPDIR)/install/bin/memcached-wrapper ns_server/bin/memcached
	ln -f -s $(TOPDIR)/install/lib/memcached/default_engine.so ns_server/lib/memcached/default_engine.so
	ln -f -s $(TOPDIR)/install/lib/memcached/stdin_term_handler.so ns_server/lib/memcached/stdin_term_handler.so
	mkdir -p ns_server/bin/bucket_engine
	ln -f -s `ls "$(TOPDIR)/install/lib/bucket_engine.so" "$(TOPDIR)/install/lib/memcached/bucket_engine.so" 2>/dev/null` ns_server/bin/bucket_engine/bucket_engine.so
	mkdir -p ns_server/bin/ep_engine
	ln -f -s `ls "$(TOPDIR)/install/lib/ep.so" "$(TOPDIR)/install/lib/memcached/ep.so" 2>/dev/null` ns_server/bin/ep_engine/ep.so
	mkdir -p ns_server/bin/moxi
	ln -f -s $(TOPDIR)/install/bin/moxi-wrapper ns_server/bin/moxi/moxi
	mkdir -p ns_server/bin/vbucketmigrator
	ln -f -s $(TOPDIR)/install/bin/vbucketmigrator ns_server/bin/vbucketmigrator/vbucketmigrator
	rm -rf ns_server/lib/couchdb
	ln -sf $(TOPDIR)/install ns_server/lib/couchdb
	ln -f -s $(TOPDIR)/install/bin/sigar_port ns_server/bin/

WIN32_MAKE_TARGET := do-install-all
WIN32_HOST := i586-mingw32msvc

win32-cross:
	$(MAKE) $(WIN32_MAKE_TARGET) FOR_WINDOWS=1 HOST=$(WIN32_HOST) CROSS_COMPILING=1

ifdef FOR_WINDOWS

BAD_FLAGS := 'LOCAL=$(PREFIX)'

ifndef LIBS_PREFIX
$(warning LIBS_PREFIX usually needs to be given so that I can find libcurl, libevent and libpthread)
else

OPTIONS += 'CFLAGS=-I$(LIBS_PREFIX)/include $(CFLAGS)' 'LDFLAGS=-L$(LIBS_PREFIX)/lib $(LDFLAGS)'
LOCALINC := -I${PREFIX}/include
LOCALINC += -I$(LIBS_PREFIX)/include
ifdef NO_USECONDS_T
LOCALINC += -Duseconds_t=unsigned
endif

BAD_FLAGS += 'LOCALINC=$(LOCALINC)' 'LIB=-L$(LIBS_PREFIX)/lib $(LIB)'

endif

ifdef HOST
OPTIONS := --host=$(HOST) $(OPTIONS)
BAD_FLAGS += CC=$(HOST)-gcc CXX=$(HOST)-g++
endif

libmemcached_OPTIONS += --without-memcached
moxi_OPTIONS += --without-memcached

memcached/Makefile:
	touch $@

ep-engine/Makefile:
	touch $@

bucket_engine/Makefile:
	touch $@

tmp/installed-memcached:
	(cd memcached && $(MAKE) -f win32/Makefile.mingw $(BAD_FLAGS) install)
	mkdir -p tmp
	touch $@

# hey, it's almost like Lisp
EP_ENGINE_MARCH := $(strip $(if $(or $(findstring x86_64, $(HOST)), $(findstring amd64, $(HOST))), ,-march=i686))

tmp/installed-ep-engine:
	chmod +x ep-engine/win32/config.sh
	(cd ep-engine && $(MAKE) -f win32/Makefile.mingw "MARCH=$(EP_ENGINE_MARCH)" $(BAD_FLAGS) all \
	 && cp .libs/ep.so "$(PREFIX)/lib" && cp management/sqlite3.exe management/mbdbconvert.exe "$(PREFIX)/bin")
	mkdir -p tmp && touch $@

tmp/installed-bucket_engine:
	(cd bucket_engine && $(MAKE) -f win32/Makefile.mingw $(BAD_FLAGS) all \
	 && cp .libs/bucket_engine.so "$(PREFIX)/lib")
	mkdir -p tmp
	touch $@

libmemcached/Makefile: fix-broken-libmemcached-tests

fix-broken-libmemcached-tests:
	patch -p1 -N -r /dev/null -t -d libmemcached <tlm/libmemcached-win32-fix.diff  || true

endif

AUTOCONF213 := autoconf213

spidermonkey/configure:
	(cd spidermonkey && $(AUTOCONF213))

spidermonkey/Makefile: spidermonkey/configure
	(cd spidermonkey && ./configure "--prefix=$(PREFIX)" --without-x)

tmp/installed-spidermonkey: spidermonkey/Makefile
	$(MAKE) -C spidermonkey
	$(MAKE) -C spidermonkey install
	mkdir -p tmp && touch $@

icu4c/source/Makefile:
	(cd icu4c/source && ./configure "--prefix=$(PREFIX)")

tmp/installed-icu4c: icu4c/source/Makefile
	$(MAKE) -C icu4c/source install
	mkdir -p tmp && touch $@

make-install-couchdb-deps: tmp/installed-spidermonkey tmp/installed-icu4c

CHECK_COMPONENTS ?= $(COMPONENTS)

CHECK_TARGETS := $(patsubst %, check-%, $(CHECK_COMPONENTS))

MAKE_CHECK_TARGET := check

check-fast: check-ns_server check-bucket_engine check-ep-engine check-ns_server check-libvbucket check-couchdb

check: $(CHECK_TARGETS)

check-memcached check-moxi check-bucket_engine check-ns_server: MAKE_CHECK_TARGET := test

$(CHECK_TARGETS): check-%: make-install-%
	$(MAKE) -C $* $(MAKE_CHECK_TARGET)

# Allow the user to override stuff for all projects (like
# --with-erlang=)
ifneq "$(realpath $(HOME)/.couchbase/build/Makefile.extra)" ""
include $(HOME)/.couchbase/build/Makefile.extra
endif

# this thing can override settings and add components
ifneq "$(realpath .repo/Makefile.extra)" ""
include .repo/Makefile.extra
endif
