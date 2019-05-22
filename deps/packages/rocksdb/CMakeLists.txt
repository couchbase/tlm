# Downloads the declared version of rocksdb and builds it.

# Download RocksDB dependencies.
SET (_dep_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
SET (_temp_cmake_install_prefix "${CMAKE_INSTALL_PREFIX}")
SET (CMAKE_INSTALL_PREFIX "${_dep_install}")
DECLARE_DEP (snappy VERSION 1.1.1 PLATFORMS windows_msvc)
DECLARE_DEP (snappy VERSION 1.1.1-cb2 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx sunos suse11.2 suse12.2 ubuntu12.04 ubuntu14.04 ubuntu16.04 ubuntu17.04 freebsd)
DECLARE_DEP (snappy VERSION 1.1.1-cb5 PLATFORMS rhel8)
DECLARE_DEP (lz4 VERSION 1.8.0-cb2 PLATFORMS centos6 centos7 debian7 debian8 debian9 macosx sunos suse11.2 suse12.2 ubuntu14.04 ubuntu16.04)
DECLARE_DEP (lz4 VERSION 1.8.0-cb4 PLATFORMS rhel8)
SET (CMAKE_INSTALL_PREFIX "${_temp_cmake_install_prefix}")

# RocksDB 5.9.2 contains new code that triggers the new GCC 7 'implicit-fallthrough' warnings.
# When we compile using the GCC '-Werror/-Wswitch' options, all the specified warnings are
# made into an error. So, we need to treat the 'implicit-fallthrough' warning as an exception until
# the RocksDB code is fixed. We use the following 'W_NO_ERROR_IMPLICIT_FALLTHROUGH'
# (if set) in 'build_rocksdb.sh'.
# RocksDB 5.10.2 contains new code that triggers the new GCC 7 'format-truncation' error.
# We need to suppress the error until the RocksDB code is fixed. We use the following
# 'W_NO_ERROR_FORMAT_TRUNCATION' (if set) in 'build_rocksdb.sh'.
if (CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 7.0)
  SET (W_NO_ERROR_IMPLICIT_FALLTHROUGH "-Wno-error=implicit-fallthrough")
  SET (W_NO_ERROR_FORMAT_TRUNCATION "-Wno-error=format-truncation")
endif()

include(ExternalProject)

### Download, configure and build rocksdb  ####################################
_DETERMINE_CPU_COUNT(_parallelism)
configure_file("build_rocksdb.sh.in" "build_rocksdb.sh")
ExternalProject_Add(rocksdb
  GIT_REPOSITORY ${_git_repo}
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
    COMMAND install_name_tool -id @rpath/librocksdb.5.18.3.dylib <BINARY_DIR>/librocksdb.5.18.3.dylib

    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
