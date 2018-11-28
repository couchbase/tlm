# Downloads the declared version of rocksdb and builds it.

# Download RocksDB dependencies.
SET (_dep_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
SET (_temp_cmake_install_prefix "${CMAKE_INSTALL_PREFIX}")
SET (CMAKE_INSTALL_PREFIX "${_dep_install}")
DECLARE_DEP (snappy VERSION 1.1.1 PLATFORMS windows_msvc)
DECLARE_DEP (snappy VERSION 1.1.1-cb2 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx sunos suse11.2 suse12.2 ubuntu12.04 ubuntu14.04 ubuntu16.04 ubuntu17.04 freebsd)
DECLARE_DEP (lz4 VERSION 1.8.0-cb2 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx sunos suse11.2 suse12.2 ubuntu14.04 ubuntu16.04)
SET (CMAKE_INSTALL_PREFIX "${_temp_cmake_install_prefix}")

include(ExternalProject)

### Download, configure and build rocksdb  ####################################
_DETERMINE_CPU_COUNT(_parallelism)
configure_file("build_rocksdb.sh.in" "build_rocksdb.sh")
ExternalProject_Add(rocksdb
  GIT_REPOSITORY https://github.com/couchbasedeps/rocksdb.git
  GIT_TAG ${_git_rev}

  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND ""

  BUILD_COMMAND "${CMAKE_CURRENT_BINARY_DIR}/build_rocksdb.sh" -j${_parallelism} shared_lib

  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND "${CMAKE_CURRENT_BINARY_DIR}/build_rocksdb.sh" INSTALL_PATH=<INSTALL_DIR> install-shared

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(rocksdb install_name
    COMMAND install_name_tool -id @rpath/librocksdb.5.8.dylib <BINARY_DIR>/librocksdb.5.8.dylib

    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
