# -*- Mode: makefile -*-

PREFIX=$(MAKEDIR)/install
MAKETYPE=NMake Makefiles
RM=rmdir
RMOPTS=/Q /S

all: build/Makefile compile

compile:
	(cd build && $(MAKE) all install)

test: all
	(cd build && $(MAKE) test)

build/Makefile: CMakeLists.txt
	@-mkdir build
	(cd build && cmake -G "$(MAKETYPE)" \
                           -D CMAKE_INSTALL_PREFIX=$(PREFIX) \
                           -D CMAKE_PREFIX_PATH=$(PREFIX) \
                           -D BUILD_ENTERPRISE=$(BUILD_ENTERPRISE) \
                           ..)

run-mats:
	cd testrunner && $(MAKE) simple-test

e2etest:
	cd testrunner && $(MAKE) test

e2eviewtests:
	cd testrunner && $(MAKE) test-views

clean:
	$(RM) $(RMOPTS) build

clean-xfd: clean
	cd ns_server && git clean -dfXq
	cd geocouch && git clean -dfXq

clean-xfd-hard: clean-xfd

clean-all: clean-xfd-hard
