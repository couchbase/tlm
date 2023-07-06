# Downloads the declared version of rocksdb and builds it.

# Download RocksDB dependencies.
SET (_dep_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
SET (_temp_cmake_install_prefix "${CMAKE_INSTALL_PREFIX}")
SET (CMAKE_INSTALL_PREFIX "${_dep_install}")
DECLARE_DEP (lz4 VERSION 1.9.2-cb5 PLATFORMS linux macosx)
DECLARE_DEP (snappy VERSION 1.1.10-cb2 PLATFORMS linux macosx windows)
DECLARE_DEP (zlib V2 VERSION 1.2.13 BUILD 2 PLATFORMS linux macosx windows)
DECLARE_DEP (zstd-cpp V2 VERSION 1.5.0 BUILD 3 PLATFORMS linux macosx windows)
SET (CMAKE_INSTALL_PREFIX "${_temp_cmake_install_prefix}")

INCLUDE(ExternalProject)

# Ensure we're landing on the right zstd
set(_zstd_cpp_rocksdb_include_dir ${CMAKE_BINARY_DIR}/rocksdb/zstd-cpp.exploded/include)
set(_zstd_cpp_rocksdb_library_dir ${CMAKE_BINARY_DIR}/rocksdb/zstd-cpp.exploded/lib)
INCLUDE(FindCouchbaseZstd)

# Figure out platform specific library name + version from the git rev
STRING (REGEX REPLACE "([0-9]+\\.[0-9]+\\.[0-9]+).*" "\\1" _rocksdb_version ${_git_rev})
if (APPLE)
    SET (package_name librocksdb.${_rocksdb_version}.dylib)
    SET (tsan_package_name librocksdbtsan.${_rocksdb_version}.dylib)
else ()
    SET (package_name librocksdb.so.${_rocksdb_version})
    SET (tsan_package_name librocksdbtsan.so.${_rocksdb_version})
endif ()

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

# We build a separate TSan library for RocksDB as we otherwise end up with some
# odd issues if the linker picks up unannotated symbols.
if (${PLATFORM} MATCHES "linux" OR ${PLATFORM} MATCHES "macos")
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
        COMMAND cp ${package_name} ${CMAKE_CURRENT_BINARY_DIR}/install/lib/${tsan_package_name}
    )
    ExternalProject_Add_StepDependencies(rocksdb download rocksdbtsan)
endif()

# OS X-only: Custom post-build step to set the shared lib install name/rpath
if (APPLE)
  ExternalProject_Add_Step(rocksdb install_name
    COMMAND install_name_tool -id @rpath/${package_name} <BINARY_DIR>/${package_name}
    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )

  ExternalProject_Add_Step(rocksdb set_rpath
    COMMAND install_name_tool -add_rpath @executable_path <BINARY_DIR>/${package_name}
    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )

  ExternalProject_Add_Step(rocksdbtsan set_rpath
    COMMAND install_name_tool -add_rpath @executable_path <BINARY_DIR>/${package_name}
    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
