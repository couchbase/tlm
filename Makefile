# -*- Mode: makefile -*-

# The default destination for installing. CMake will also search for
# dependencies in this directory, so you may pre-build dependencies
# that you wish to ship with your compiled Couchbase into this
# directory.
PREFIX=$(MAKEDIR)\\install
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

CMAKE=cmake

CMAKE_ARGS=-G "$(MAKETYPE)" -D CMAKE_INSTALL_PREFIX="$(PREFIX)" \
                            -D CMAKE_PREFIX_PATH="$(CMAKE_PREFIX_PATH);$(PREFIX)" \
                            -D PRODUCT_VERSION=$(PRODUCT_VERSION) \
                            -D BUILD_ENTERPRISE=$(BUILD_ENTERPRISE) \
                            -D CMAKE_BUILD_TYPE=$(BUILD_TYPE) \
                            $(EXTRA_CMAKE_OPTIONS)


all: build/Makefile compile

compile: build/Makefile
	(cd build && $(MAKE) all install)

test: all
	(cd build && $(MAKE) test)

build/Makefile: CMakeLists.txt
	@-mkdir build
	(cd build && $(CMAKE) $(CMAKE_ARGS) ..)

# Invoke static analyser. Requires Clang Static Analyser
# (http://clang-analyzer.llvm.org). See tlm/README.markdown for more information.
analyze:
	@-mkdir build-analyzer
	(cd build-analyzer && 				\
	 scan-build --use-analyzer=Xcode $(CMAKE) $(CMAKE_ARGS) .. && \
	 scan-build --use-analyzer=Xcode -o analyser-results/ $(MAKE) all)

run-mats:
	cd testrunner && $(MAKE) simple-test

e2etest:
	cd testrunner && $(MAKE) test

e2eviewtests:
	cd testrunner && $(MAKE) test-views

clean:
	-$(RM) $(RMOPTS) build $(PREFIX)

clean-xfd: clean
	cd couchdb && git clean -dfxq
	cd ns_server && git clean -dfxq
	cd geocouch && git clean -dfxq

clean-xfd-hard: clean-xfd

clean-all: clean-xfd-hard
