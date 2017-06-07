#
# This is the toplevel CMakeLists.txt that is used to build Couchbase
#
CMAKE_MINIMUM_REQUIRED(VERSION 2.8.12)

IF (NOT(${CMAKE_MAJOR_VERSION} LESS 3))
  CMAKE_POLICY(SET CMP0026 OLD)
ENDIF (NOT(${CMAKE_MAJOR_VERSION} LESS 3))

STRING(REGEX REPLACE "[ ]" "a" modified_source_dir "${CMAKE_SOURCE_DIR}")
IF (NOT modified_source_dir STREQUAL CMAKE_SOURCE_DIR)
  MESSAGE(FATAL_ERROR "Couchbase cannot be built in a source directory containing a space character")
ENDIF (NOT modified_source_dir STREQUAL CMAKE_SOURCE_DIR)

STRING(REGEX REPLACE "[ ]" "a" modified_binary_dir "${CMAKE_BINARY_DIR}")
IF (NOT modified_binary_dir STREQUAL CMAKE_BINARY_DIR)
  MESSAGE(FATAL_ERROR "Couchbase cannot be built in a build directory containing a space character")
ENDIF (NOT modified_binary_dir STREQUAL CMAKE_BINARY_DIR)


# The PROJECT() macro sets it's own default build type, so need to specify
# ours first.
IF (NOT DEFINED CMAKE_BUILD_TYPE)
   SET(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING
       "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel."
       FORCE)
ENDIF ()

PROJECT("Couchbase")

OPTION(COUCHBASE_KV_COMMIT_VALIDATION
       "Only build modules used by KV commit validation"
       OFF)

IF ($ENV{JETBRAINS_IDE})
   SET(JETBRAINS_CLION_IDE True CACHE BOOL "Build Couchbase under CLion")
ENDIF ($ENV{JETBRAINS_IDE})

IF (DEFINED JETBRAINS_CLION_IDE)
   # CLion tries to autodetect all of the different configuration
   # types and generate projects for them. That cause a race condition
   # with the population pf the precompiled binaries we've got
   # making an incomplete configuration. To work around that,
   # let's just remove all of the other configurations and just
   # build a debug build
   SET(CMAKE_CONFIGURATION_TYPES Debug CACHE STRING "" FORCE)
   ADD_DEFINITIONS(-DJETBRAINS_CLION_IDE)
ENDIF (DEFINED JETBRAINS_CLION_IDE)

# RPATH is more or less "broken" on MacOSX in cmake < 3.x
IF (APPLE)
   IF (${CMAKE_MAJOR_VERSION} LESS 3)
      MESSAGE(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
      MESSAGE(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
      MESSAGE(STATUS "@@@ The version of cmake you're using  @@@")
      MESSAGE(STATUS "@@@ does not properly handle $RPATH    @@@")
      MESSAGE(STATUS "@@@ RPATH for macosx was introduced in @@@")
      MESSAGE(STATUS "@@@ cmake 3.0.0                        @@@")
      MESSAGE(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
      MESSAGE(STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
      MESSAGE(FATAL_ERROR "Please upgrade cmake")
   ENDIF (${CMAKE_MAJOR_VERSION} LESS 3)
ENDIF(APPLE)

IF (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  SET(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/install" CACHE STRING
      "The install location" FORCE)
  LIST(APPEND CMAKE_PREFIX_PATH "${CMAKE_INSTALL_PREFIX}")
ENDIF (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/tlm/cmake/Modules/")
SET(COUCHBASE_SERVER_BUILD True CACHE BOOL "Indicating this is a server build")

# Try to download the prebuilt 3rd-party dependencies by default
IF (NOT DEFINED CB_DOWNLOAD_DEPS)
   SET(CB_DOWNLOAD_DEPS True
       CACHE BOOL "Download prebuilt dependencies by default")
ENDIF (NOT DEFINED CB_DOWNLOAD_DEPS)

# Have to add deps first, before any other part of the build tries to
# FIND anything
ADD_SUBDIRECTORY(tlm/deps)

INCLUDE(CouchbaseDefaultValues)

# If the user has synced any closed-source code, assume building EE
IF (EXISTS "${PROJECT_SOURCE_DIR}/goproj/src/github.com/couchbase/backup")
  SET (_ee_found ON)
ELSE ()
  SET (_ee_found OFF)
ENDIF()
OPTION (BUILD_ENTERPRISE "Building Enterprise Edition" ${_ee_found})

# Build 'developer builds' by default
OPTION (CB_DEVELOPER_BUILD "Produce Developer builds" ON)

MESSAGE(STATUS "Using cmake version: ${CMAKE_VERSION}")
MESSAGE(STATUS "Installing to ${CMAKE_INSTALL_PREFIX}")
MESSAGE(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

INCLUDE(CouchbaseAddressSanitizer)
INCLUDE(CouchbaseAsciiDocs)
INCLUDE(CouchbaseThreadSanitizer)
INCLUDE(CouchbaseMemoryAllocator)

INCLUDE(FindCouchbaseBoost)
INCLUDE(FindCouchbaseOpenSSL)
INCLUDE(FindCouchbaseLibevent)
INCLUDE(FindCouchbaseCurl)
INCLUDE(FindCouchbaseIcu)
INCLUDE(FindCouchbaseSnappy)
INCLUDE(FindCouchbaseLua)
INCLUDE(FindCouchbasePythonInterp)
INCLUDE(FindCouchbaseErlang)
INCLUDE(FindCouchbaseDtrace)
INCLUDE(FindCouchbaseGo)
INCLUDE(FindCouchbaseBreakpad)
INCLUDE(FindCouchbaseFlatbuffers)
INCLUDE(FindCouchbaseValgrind)
INCLUDE(CouchbaseCompilerOptions)
INCLUDE(FindCouchbaseV8)
INCLUDE(FindCouchbaseNlohmannJson)
INCLUDE(FindCouchbaseMaven)

# Declare PRODUCT_VERSION in cache, but then override user-defined value
# if it is an empty string
SET (PRODUCT_VERSION "" CACHE STRING "Product version with build number")
IF ("${PRODUCT_VERSION}" STREQUAL "")
  IF (PYTHON_EXECUTABLE)
    # Try to determine product version from manifest
    EXECUTE_PROCESS(COMMAND ${PYTHON_EXECUTABLE} tlm/scripts/get_version.py
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      OUTPUT_VARIABLE _product_version
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  ELSE (PYTHON_EXECUTABLE)
    SET(_product_version "0.0.0-9999")
  ENDIF (PYTHON_EXECUTABLE)
  SET (PRODUCT_VERSION ${_product_version} CACHE STRING "Product version with build number" FORCE)
ENDIF ("${PRODUCT_VERSION}" STREQUAL "")

IF (BUILD_ENTERPRISE)
  MESSAGE (STATUS "Building Couchbase Server ${PRODUCT_VERSION} Enterprise Edition")
ELSE ()
  MESSAGE (STATUS "Building Couchbase Server ${PRODUCT_VERSION} Community Edition")
ENDIF ()

IF (WIN32)
   SET(COUCHBASE_NETWORK_LIBS "Ws2_32")
ELSEIF ("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS")
   SET(COUCHBASE_NETWORK_LIBS socket nsl)
ENDIF (WIN32)
MESSAGE(STATUS "Linking with network libraries: ${COUCHBASE_NETWORK_LIBS}")

IF (NOT WIN32)
   SET(COUCHBASE_MATH_LIBS m)
ENDIF(NOT WIN32)

INCLUDE(CouchbaseCodeCoverage)

INCLUDE(TestBigEndian)
TEST_BIG_ENDIAN(WORDS_BIG_ENDIAN)
IF (WORDS_BIG_ENDIAN)
  MESSAGE(STATUS "Builing on big endian system")
  ADD_DEFINITIONS(-DWORDS_BIGENDIAN=1)
ENDIF(WORDS_BIG_ENDIAN)

ENABLE_TESTING()

INCLUDE_DIRECTORIES(BEFORE ${CMAKE_BINARY_DIR}/platform/include)
INCLUDE_DIRECTORIES(AFTER ${NLOHMANN_JSON_INCLUDE_DIR})

# Add a quick (and safe) way to nuke everything
ADD_CUSTOM_TARGET(reset
                  COMMAND repo forall -c "git clean -dfx"
                  VERBATIM)

SET (gtest_force_shared_crt ON CACHE BOOL
     "Use shared (DLL) run-time lib even when Google Test is built as static lib.")
ADD_SUBDIRECTORY(googletest EXCLUDE_FROM_ALL)

ADD_SUBDIRECTORY(benchmark EXCLUDE_FROM_ALL)

ADD_SUBDIRECTORY(phosphor)
OPTION(PHOSPHOR_DISABLE "Disable compilation of Phosphor trace points into components" OFF)

IF (PHOSPHOR_DISABLE)
    ADD_DEFINITIONS(-DPHOSPHOR_DISABLED=1)
    SET(PHOSPHOR_LIB "")
ENDIF (PHOSPHOR_DISABLE)

ADD_SUBDIRECTORY(platform)
ADD_SUBDIRECTORY(subjson)
ADD_SUBDIRECTORY(kv_engine/include)
ADD_SUBDIRECTORY(couchstore)
IF (NOT COUCHBASE_KV_COMMIT_VALIDATION)
    ADD_SUBDIRECTORY(forestdb)
    SET (FORESTDB_INCLUDE_DIR "${ForestDB_SOURCE_DIR}/include")
    GET_PROPERTY (_dir TARGET forestdb PROPERTY LOCATION)
    GET_FILENAME_COMPONENT (FORESTDB_LIBRARY_DIR "${_dir}" PATH)
    SET (FORESTDB_TARGET forestdb)
ENDIF()
ADD_SUBDIRECTORY(kv_engine)
ADD_SUBDIRECTORY(sigar)
ADD_SUBDIRECTORY(moxi)

IF (NOT COUCHBASE_KV_COMMIT_VALIDATION)
    ADD_SUBDIRECTORY(couchbase-cli)
    ADD_SUBDIRECTORY(couchdb)
    ADD_SUBDIRECTORY(geocouch)
    ADD_SUBDIRECTORY(query-ui)

    SET (GODEPSDIR "${CMAKE_CURRENT_SOURCE_DIR}/godeps")

    ADD_SUBDIRECTORY(ns_server ${CMAKE_CURRENT_SOURCE_DIR}/ns_server/build)

    ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/query)
    ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/indexing)
    ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/goxdcr)
    ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/gometa)
    ADD_SUBDIRECTORY(godeps/src/github.com/couchbase/cbauth)

    ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/cbft)
    ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/docloader)

    # Analytics CBGT connector
    IF(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/goproj/src/github.com/couchbaselabs/cbas")
      ADD_SUBDIRECTORY(goproj/src/github.com/couchbaselabs/cbas)
    ENDIF()

    # Analytics Maven project
    IF (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/analytics")
      ADD_SUBDIRECTORY (analytics)
    ENDIF ()

    IF (BUILD_ENTERPRISE AND EXISTS "${PROJECT_SOURCE_DIR}/goproj/src/github.com/couchbase/backup")
      ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/backup)
    ENDIF()
ENDIF (NOT COUCHBASE_KV_COMMIT_VALIDATION)

IF (NOT WIN32)
   CONFIGURE_FILE(tlm/memcached-wrapper.in ${CMAKE_BINARY_DIR}/tlm/memcached-wrapper)
   CONFIGURE_FILE(tlm/moxi-wrapper.in ${CMAKE_BINARY_DIR}/tlm/moxi-wrapper)
ENDIF (NOT WIN32)
