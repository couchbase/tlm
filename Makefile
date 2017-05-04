# -*- Mode: makefile -*-

# PLEASE NOTE: This Makefile is provided as a convenience for those
# who do not wish to interact with CMake. It is NOT SUPPORTED by the
# Couchbase build team, and the production builds do NOT make use of
# it, so bugs filed against it will need to be handled by those devs
# who care to use it.

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
# Other options you would like to pass to cmake
EXTRA_CMAKE_OPTIONS=
# Command used to remove read only flag for files
CHMODCMD=attrib -r
# Command used for copying files
CP=copy
# path separator
SEPARATOR=\\

CMAKE=cmake

CMAKE_ARGS=-G "$(MAKETYPE)" $(EXTRA_CMAKE_OPTIONS)


all: CMakeLists.txt Makefile GNUmakefile build/Makefile compile

compile: build/Makefile
	(cd build && $(MAKE) all install)

test: all
	(cd build && $(MAKE) test)

build/Makefile: CMakeLists.txt
	@-mkdir build
	(cd build && $(CMAKE) $(CMAKE_ARGS) ..)

CMakeLists.txt: tlm/CMakeLists.txt
	$(CHMODCMD) CMakeLists.txt
	$(CP) tlm$(SEPARATOR)CMakeLists.txt CMakeLists.txt

GNUmakefile: tlm/GNUmakefile
	$(CHMODCMD) GNUmakefile
	$(CP) tlm$(SEPARATOR)GNUmakefile GNUmakefile

Makefile: tlm/Makefile
	$(CHMODCMD) Makefile
	$(CP) tlm$(SEPARATOR)Makefile Makefile


# Invoke static analyser. Requires Clang Static Analyser
# (http://clang-analyzer.llvm.org). See tlm/README.markdown for more
# information.
analyze:
	@-mkdir build-analyzer
	(cd build-analyzer && 				\
	 scan-build --use-analyzer=Xcode $(CMAKE) $(CMAKE_ARGS) -DCOUCHBASE_DISABLE_CCACHE=1 .. && \
	 scan-build --use-analyzer=Xcode -o analyser-results/ $(MAKE) all)

# geocouch needs a special build for running the unit tests
geocouch-build-for-testing: compile
	@-mkdir build/geocouch-for-tests
	(cd build/geocouch-for-tests && \
	 $(CMAKE) $(CMAKE_ARGS) -D CMAKE_INSTALL_PREFIX="$(PREFIX)" \
	 -D GEOCOUCH_BUILD_FOR_UNIT_TESTS=1 ../../geocouch && \
	 $(MAKE))

analytics-install: build/Makefile
	(cd build && make analytics)

run-mats:
	cd testrunner && $(MAKE) simple-test

e2etest:
	cd testrunner && $(MAKE) test

e2eviewtests:
	cd testrunner && $(MAKE) test-views

clean:
	-(cd build && $(MAKE) realclean)
	-$(RM) $(RMOPTS) build ns_server$(SEPARATOR)build

reset:
	(cd build && $(MAKE) reset)

clean-xfd: clean
	-(cd ns_server && git clean -dfxq)

clean-xfd-hard: clean-xfd

clean-all: clean-xfd-hard
