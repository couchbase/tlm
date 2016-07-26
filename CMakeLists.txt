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

IF ("" STREQUAL "${BUILD_ENTERPRISE}")
   SET(CB_BUILD_TYPE "Community Edition")
ELSE ("" STREQUAL "${BUILD_ENTERPRISE}")
   SET(CB_BUILD_TYPE "Enterprise Edition")
ENDIF ("" STREQUAL "${BUILD_ENTERPRISE}")

MESSAGE(STATUS "Using cmake version: ${CMAKE_VERSION}")
MESSAGE(STATUS "Installing to ${CMAKE_INSTALL_PREFIX}")
MESSAGE(STATUS "Build type: ${CMAKE_BUILD_TYPE} (${CB_BUILD_TYPE})")

INCLUDE(CouchbaseAddressSanitizer)
INCLUDE(CouchbaseThreadSanitizer)
INCLUDE(CouchbaseMemoryAllocator)

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

# Add a quick (and safe) way to nuke everything
ADD_CUSTOM_TARGET(reset
                  COMMAND repo forall -c "git clean -dfx"
                  VERBATIM)

SET (gtest_force_shared_crt ON CACHE BOOL
     "Use shared (DLL) run-time lib even when Google Test is built as static lib.")
ADD_SUBDIRECTORY(googletest EXCLUDE_FROM_ALL)

ADD_SUBDIRECTORY(platform)
ADD_SUBDIRECTORY(subjson)
ADD_SUBDIRECTORY(memcached)
ADD_SUBDIRECTORY(couchstore)
ADD_SUBDIRECTORY(forestdb)
ADD_SUBDIRECTORY(ep-engine)

IF (NOT DEFINED COUCHBASE_KV_COMMIT_VALIDATION)
   ADD_SUBDIRECTORY(couchbase-cli)
   ADD_SUBDIRECTORY(couchbase-examples)
ENDIF (NOT DEFINED COUCHBASE_KV_COMMIT_VALIDATION)

ADD_SUBDIRECTORY(sigar)
ADD_SUBDIRECTORY(moxi)

IF (NOT DEFINED COUCHBASE_KV_COMMIT_VALIDATION)
    ADD_SUBDIRECTORY(couchdb)
    ADD_SUBDIRECTORY(geocouch)
    ADD_SUBDIRECTORY(query-ui)
ENDIF (NOT DEFINED COUCHBASE_KV_COMMIT_VALIDATION)

SET (GODEPSDIR "${CMAKE_CURRENT_SOURCE_DIR}/godeps")

IF (NOT DEFINED JETBRAINS_CLION_IDE AND NOT DEFINED COUCHBASE_KV_COMMIT_VALIDATION)

  # The CLion IDE from JetBrains don't support building "in source",
  # so let's just skip ns_server in that configuration (we don't use
  # CLion for Erlang development anyway...
  ADD_SUBDIRECTORY(ns_server ${CMAKE_CURRENT_SOURCE_DIR}/ns_server/build)
ENDIF (NOT DEFINED JETBRAINS_CLION_IDE AND NOT DEFINED COUCHBASE_KV_COMMIT_VALIDATION)

IF (NOT DEFINED COUCHBASE_KV_COMMIT_VALIDATION)
    ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/query)
    SET (FORESTDB_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/forestdb/include")
    GET_PROPERTY (_dir TARGET forestdb PROPERTY LOCATION)
    GET_FILENAME_COMPONENT (FORESTDB_LIBRARY_DIR "${_dir}" PATH)
    SET (FORESTDB_TARGET forestdb)
    ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/indexing)
    ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/goxdcr)
    ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/gometa)
    ADD_SUBDIRECTORY(godeps/src/github.com/couchbase/cbauth)

    ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/cbft)

    IF(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/goproj/src/github.com/couchbase/backup")
      ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/backup)
    ENDIF(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/goproj/src/github.com/couchbase/backup")
ENDIF (NOT DEFINED COUCHBASE_KV_COMMIT_VALIDATION)

IF (NOT WIN32)
   CONFIGURE_FILE(tlm/memcached-wrapper.in ${CMAKE_BINARY_DIR}/tlm/memcached-wrapper)
   CONFIGURE_FILE(tlm/moxi-wrapper.in ${CMAKE_BINARY_DIR}/tlm/moxi-wrapper)
ENDIF (NOT WIN32)
