# Downloads the declared version of rocksdb and builds it.

# Download RocksDB dependencies.
SET (_dep_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
SET (_temp_cmake_install_prefix "${CMAKE_INSTALL_PREFIX}")
SET (CMAKE_INSTALL_PREFIX "${_dep_install}")
DECLARE_DEP (snappy VERSION 1.1.1 PLATFORMS windows_msvc2017)
DECLARE_DEP (snappy VERSION 1.1.1-cb5 PLATFORMS amzn2 centos7 debian9 debian10 macosx suse12 suse15 ubuntu18.04 ubuntu20.04)
DECLARE_DEP (lz4 VERSION 1.9.2-cb1 PLATFORMS amzn2 centos7 centos8 debian9 debian10 macosx rhel8 suse12 suse15 ubuntu16.04 ubuntu18.04 ubuntu20.04)
SET (CMAKE_INSTALL_PREFIX "${_temp_cmake_install_prefix}")

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
