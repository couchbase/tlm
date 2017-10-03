# Downloads the declared version of rocksdb and builds it.

# Download the Snappy dependency.
SET (_snappy_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
SET (_temp_cmake_install_prefix "${CMAKE_INSTALL_PREFIX}")
SET (CMAKE_INSTALL_PREFIX "${_snappy_install}")
DECLARE_DEP (snappy VERSION 1.1.1 PLATFORMS windows_msvc)
DECLARE_DEP (snappy VERSION 1.1.1-cb2 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx sunos suse11.2 suse12.2 ubuntu12.04 ubuntu14.04 ubuntu16.04 ubuntu17.04 freebsd)
SET (CMAKE_INSTALL_PREFIX "${_temp_cmake_install_prefix}")

include(ExternalProject)

### Download, configure and build rocksdb  ####################################
ExternalProject_Add(rocksdb
  GIT_REPOSITORY https://github.com/couchbasedeps/rocksdb.git
  GIT_TAG ${_git_rev}

  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND ""

  BUILD_COMMAND PLATFORM_LDFLAGS=-L${_snappy_install}/lib CFLAGS=-I${_snappy_install}/include PORTABLE=1 $(MAKE) shared_lib

  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) INSTALL_PATH=<INSTALL_DIR> install-shared

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(rocksdb install_name
    COMMAND install_name_tool -id @rpath/librocksdb.5.6.dylib <BINARY_DIR>/librocksdb.5.6.dylib

    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
