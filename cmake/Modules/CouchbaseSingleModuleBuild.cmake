#
# The content of this module is used during the transition from
# GNU Autotools to CMake. When we replace the top level makefile
# with CMake the content of this file should be moved there..
#
INCLUDE(CouchbaseDefaultValues)

MESSAGE(STATUS "Using cmake version: ${CMAKE_VERSION}")
MESSAGE(STATUS "Installing to ${CMAKE_INSTALL_PREFIX}")

INCLUDE(FindCouchbaseOpenSSL)
INCLUDE(FindCouchbaseLibevent)
INCLUDE(FindCouchbaseTcMalloc)
INCLUDE(FindCouchbaseJemalloc)
INCLUDE(FindCouchbaseCurl)
INCLUDE(FindCouchbaseIcu)
INCLUDE(FindCouchbaseSnappy)
INCLUDE(FindCouchbaseV8)
INCLUDE(FindCouchbaseLua)
INCLUDE(FindCouchbasePythonInterp)
INCLUDE(FindCouchbaseErlang)
INCLUDE(FindCouchbaseDtrace)
INCLUDE(FindCouchbaseGo)

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

ENABLE_TESTING()
