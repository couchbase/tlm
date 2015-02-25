#
# Choose deployment target on MacOS
#
IF (APPLE)
  # See http://www.couchbase.com/issues/browse/MB-11442
  SET (CMAKE_OSX_DEPLOYMENT_TARGET "10.7" CACHE STRING
    "Minimum supported version of MacOS X")
ENDIF (APPLE)

# Create a list of all of the directories we would like to be treated
# as system headers (and not report compiler warnings from (if the
# compiler supports it). This is used by the compiler-specific Options
# cmake files below.
#
# Note that as a side-effect this will change the compiler
# search order - non-system paths (-I) are searched before
# system paths.
# Therefore if a header file exists both in a standard
# system location (e.g. /usr/local/include) and in one of
# our paths then adding to CB_SYSTEM_HEADER_DIRS may
# result in the compiler picking up the wrong version.
# As a consequence of this we only add headers which
# (1) have known warning issues and (2) are unlikely
# to exist in a normal system location.

# Explicitly add Google Breakpad as it's headers have
# many warnings :(
IF (IS_DIRECTORY "${BREAKPAD_INCLUDE_DIR}")
   LIST(APPEND CB_SYSTEM_HEADER_DIRS "${BREAKPAD_INCLUDE_DIR}")
ENDIF (IS_DIRECTORY "${BREAKPAD_INCLUDE_DIR}")

#
# Set flags for the C Compiler
#
IF ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
  INCLUDE(CouchbaseGccOptions)
ELSEIF ("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
  INCLUDE(CouchbaseClangOptions)
ELSEIF ("${CMAKE_C_COMPILER_ID}" STREQUAL "MSVC")
  INCLUDE(CouchbaseMsvcOptions)
ELSEIF ("${CMAKE_C_COMPILER_ID}" STREQUAL "SunPro")
  INCLUDE(CouchbaseSproOptions)
ENDIF ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")

#
# Set flags for the C++ compiler
#
IF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  INCLUDE(CouchbaseGxxOptions)
ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
  INCLUDE(CouchbaseClangxxOptions)
ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
  INCLUDE(CouchbaseMsvcxxOptions)
ELSEIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "SunPro")
  INCLUDE(CouchbaseSproxxOptions)
ENDIF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")

# Add common -D sections
INCLUDE(CouchbaseDefinitions)

# Setup the RPATH
INCLUDE(CouchbaseRpath)

IF (NOT DEFINED COUCHBASE_DISABLE_CCACHE)
   FIND_PROGRAM(CCACHE ccache)
   IF (CCACHE)
      MESSAGE(STATUS "ccache is available as ${CCACHE}, using it")
      SET_PROPERTY(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ${CCACHE})
      SET_PROPERTY(GLOBAL PROPERTY RULE_LAUNCH_LINK ${CCACHE})
   ENDIF (CCACHE)
ENDIF (NOT DEFINED COUCHBASE_DISABLE_CCACHE)
