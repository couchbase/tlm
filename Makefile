# -*- Mode: makefile -*-

# The deault destination for the installed data
PREFIX=$(MAKEDIR)/install
# The makefile type to generate
MAKETYPE=NMake Makefiles
# The command used to delete directories
RM=rmdir
# Options passed to the command to nuke directories
RMOPTS=/Q /S
# The kind of build type: Debug, Release, RelWithDebInfo or MinSizeRel
BUILD_TYPE=Debug
# Other options you would like to pass to cmake
EXTRA_CMAKE_OPTIONS=

all: build/Makefile compile

compile: build/Makefile
	(cd build && $(MAKE) all install)

test: all
	(cd build && $(MAKE) test)

build/Makefile: CMakeLists.txt
	@-mkdir build
	(cd build && cmake -G "$(MAKETYPE)" \
                           -D CMAKE_INSTALL_PREFIX=$(PREFIX) \
                           -D CMAKE_PREFIX_PATH=$(PREFIX) \
                           -D PRODUCT_VERSION=$(PRODUCT_VERSION) \
                           -D BUILD_ENTERPRISE=$(BUILD_ENTERPRISE) \
                           -D CMAKE_BUILD_TYPE=$(BUILD_TYPE) \
                           $(EXTRA_CMAKE_OPTIONS) \
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
