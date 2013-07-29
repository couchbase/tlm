#
# The content of this module is used during the transition from
# GNU Autotools to CMake. When we replace the top level makefile
# with CMake the content of this file should be moved there..
#
INCLUDE(CouchbaseDefaultValues)

MESSAGE(STATUS "Extra dependency include directory: ${DEPS_INCLUDE_DIR}")
MESSAGE(STATUS "Extra dependency library directory: ${DEPS_LIB_DIR}")

INCLUDE(FindLibevent)
INCLUDE(FindTcMalloc)
INCLUDE(FindLua51)
INCLUDE(FindCouchbaseCurl)
INCLUDE(FindIcu)
INCLUDE(FindSnappy)
INCLUDE(FindV8)
INCLUDE(FindGTest)
INCLUDE(FindPythonInterp)

IF (WIN32)
   SET(COUCHBASE_NETWORK_LIBS "Ws2_32")
ELSEIF ("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS")
   SET(COUCHBASE_NETWORK_LIBS socket nsl)
ENDIF (WIN32)
MESSAGE(STATUS "Linking with network libraries: ${COUCHBASE_NETWORK_LIBS}")

IF (WIN32)
   SET(MISSING_DEPENDENCY_SEVERITY STATUS)
ELSE (WIN32)
   SET(MISSING_DEPENDENCY_SEVERITY SEND_ERROR)
ENDIF (WIN32)

IF (!PYTHONINTERP_FOUND)
   MESSAGE(${MISSING_DEPENDENCY_SEVERITY} "Could not find Python interpreter")
ENDIF (!PYTHONINTERP_FOUND)
IF (!V8_FOUND)
   MESSAGE(${MISSING_DEPENDENCY_SEVERITY} "Could NOT find v8")
ENDIF (!V8_FOUND)
IF (!SNAPPY_FOUND)
   MESSAGE(${MISSING_DEPENDENCY_SEVERITY} "Could NOT find snappy")
ENDIF (!SNAPPY_FOUND)
IF (!ICU_FOUND)
   MESSAGE(${MISSING_DEPENDENCY_SEVERITY} "Could NOT find ICU4C")
ENDIF (!ICU_FOUND)
IF (!CURL_FOUND)
   MESSAGE(${MISSING_DEPENDENCY_SEVERITY} "Could NOT find cURL")
ENDIF (!CURL_FOUND)
IF (!LIBEVENT_FOUND)
   MESSAGE(${MISSING_DEPENDENCY_SEVERITY} "Could NOT find libevent")
ENDIF (!LIBEVENT_FOUND)

INCLUDE(CouchbaseCompilerOptions)

ENABLE_TESTING()
