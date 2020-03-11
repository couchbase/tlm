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
SET(W_NO_ERROR_FLAGS "")
if (CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 7.0)
    STRING (APPEND "-Wno-error=implicit-fallthrough ")
    STRING (APPEND "-Wno-error=format-truncation ")
endif()

# More warnings that we need to ignore on our mac builders as they use new
# versions of Clang/XCode
if (APPLE)
    STRING(APPEND W_NO_ERROR_FLAGS "-Wno-error=shadow ")
    STRING(APPEND W_NO_ERROR_FLAGS "-Wno-error=invalid-pp-token ")
    STRING(APPEND W_NO_ERROR_FLAGS "-Wno-error=defaulted-function-deleted ")
endif(APPLE)

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

# This is trash, but the naming style of these shared libraries makes it a pain
# in the ass to rename and this is simple.
if (APPLE)
    SET (package_name librocksdb.5.18.3.dylib)
    SET (tsan_package_name librocksdbtsan.5.18.3.dylib)
else (APPLE)
    SET (package_name librocksdb.so.5.18.3)
    SET (tsan_package_name librocksdbtsan.so.5.18.3)
endif(APPLE)

# We build a separate TSan library for RocksDB as we otherwise end up with some
# odd issues if the linker picks up unannotated symbols.
# We generally only run TSan on ubuntu dockers, but on occasionally a local
# build is required. Only build the TSan package on ubuntu and macos platforms
# to save time.
if (${PLATFORM} MATCHES "ubuntu" OR ${PLATFORM} MATCHES "macos")
    ExternalProject_Add(rocksdbtsan
        # Steps should be same as normal RocksDB build
        GIT_REPOSITORY ${_git_repo}
        GIT_TAG ${_git_rev}
        BUILD_IN_SOURCE 1
        CONFIGURE_COMMAND ""
        BUILD_COMMAND "${CMAKE_CURRENT_BINARY_DIR}/build_rocksdb.sh" -j${_parallelism} shared_lib

        CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install -D CMAKE_CXX_FLAGS=-fsanitize=thread

        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        INSTALL_COMMAND "${CMAKE_CURRENT_BINARY_DIR}/build_rocksdb.sh" INSTALL_PATH=<INSTALL_DIR> install-shared

        COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt

        # Rename the current package so that we can ship both together and pick
        # the correct one when we build.
        COMMAND ls &&
        cp ${package_name} ${CMAKE_CURRENT_BINARY_DIR}/install/lib/${tsan_package_name}
    )
    ExternalProject_Add_StepDependencies(rocksdb download rocksdbtsan)
endif()

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(rocksdb install_name
    COMMAND install_name_tool -id @rpath/${package_name} <BINARY_DIR>/${package_name}

    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
