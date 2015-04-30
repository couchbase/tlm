#
# This is the toplevel CMakeLists.txt that is used to build Couchbase
#
CMAKE_MINIMUM_REQUIRED(VERSION 2.8.10)
PROJECT("Couchbase")

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

INCLUDE(CouchbaseMemoryAllocator)

INCLUDE(FindCouchbaseOpenSSL)
INCLUDE(FindCouchbaseLibevent)
INCLUDE(FindCouchbaseCurl)
INCLUDE(FindCouchbaseIcu)
INCLUDE(FindCouchbaseSnappy)
INCLUDE(FindCouchbaseV8)
INCLUDE(FindCouchbaseLua)
INCLUDE(FindCouchbasePythonInterp)
INCLUDE(FindCouchbaseErlang)
INCLUDE(FindCouchbaseDtrace)
INCLUDE(FindCouchbaseGo)
INCLUDE(FindCouchbaseBreakpad)
INCLUDE(FindCouchbaseFlatbuffers)
INCLUDE(FindCouchbaseValgrind)

IF (WIN32)
   SET(COUCHBASE_NETWORK_LIBS "Ws2_32")
ELSEIF ("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS")
   SET(COUCHBASE_NETWORK_LIBS socket nsl)
ENDIF (WIN32)
MESSAGE(STATUS "Linking with network libraries: ${COUCHBASE_NETWORK_LIBS}")

IF (NOT WIN32)
   SET(COUCHBASE_MATH_LIBS m)
ENDIF(NOT WIN32)

INCLUDE(CouchbaseCompilerOptions)
INCLUDE(CouchbaseCodeCoverage)

ENABLE_TESTING()

INCLUDE_DIRECTORIES(BEFORE ${CMAKE_BINARY_DIR}/platform/include)

# Add a quick (and safe) way to nuke everything
ADD_CUSTOM_TARGET(reset
                  COMMAND repo forall -c "git clean -dfx"
                  VERBATIM)

ADD_SUBDIRECTORY(platform)
SET (gtest_force_shared_crt ON)
ADD_SUBDIRECTORY(gtest)
ADD_SUBDIRECTORY(subjson)
ADD_SUBDIRECTORY(memcached)
ADD_SUBDIRECTORY(couchstore)
ADD_SUBDIRECTORY(forestdb)
ADD_SUBDIRECTORY(ep-engine)
ADD_SUBDIRECTORY(couchbase-cli)
ADD_SUBDIRECTORY(couchbase-examples)
ADD_SUBDIRECTORY(couchbase-python-client)
ADD_SUBDIRECTORY(sigar)
ADD_SUBDIRECTORY(moxi)
ADD_SUBDIRECTORY(couchdb)
ADD_SUBDIRECTORY(geocouch)
ADD_SUBDIRECTORY(ns_server ${CMAKE_CURRENT_SOURCE_DIR}/ns_server/build)

SET (GODEPSDIR "${CMAKE_CURRENT_SOURCE_DIR}/godeps")
ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/query)

SET (FORESTDB_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/forestdb/include")
GET_PROPERTY (_dir TARGET forestdb PROPERTY LOCATION)
GET_FILENAME_COMPONENT (FORESTDB_LIBRARY_DIR "${_dir}" PATH)
SET (FORESTDB_TARGET forestdb)
ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/indexing)
ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/goxdcr)
ADD_SUBDIRECTORY(goproj/src/github.com/couchbase/gometa)
ADD_SUBDIRECTORY(godeps/src/github.com/couchbase/cbauth)
