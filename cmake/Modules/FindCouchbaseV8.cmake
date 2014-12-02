# Locate v8 library
# This module defines
#  V8_FOUND, if false, do not try to link with v8
#  V8_LIBRARIES, Library path and libs
#  V8_INCLUDE_DIR, where to find the ICU headers

FIND_PATH(V8_INCLUDE_DIR v8.h
          HINTS
               ENV V8_DIR
          PATH_SUFFIXES include
          PATHS
               ~/Library/Frameworks
               /Library/Frameworks
               /opt/local
               /opt/csw
               /opt/v8
               /opt)

FIND_LIBRARY(V8_LIBRARIES
             NAMES v8
             HINTS
                 ENV V8_DIR
             PATHS
                 ~/Library/Frameworks
                 /Library/Frameworks
                 /opt/local
                 /opt/csw
                 /opt/v8
                 /opt)

IF (V8_LIBRARIES)
  MESSAGE(STATUS "Found v8 in ${V8_INCLUDE_DIR} : ${V8_LIBRARIES}")

  IF (WIN32)
    SET(V8C_VERSION "V8_POST_3_19_API")
  ELSE (WIN32)
    TRY_RUN(V8C_EXITCODE V8C_COMPILED
            ${CMAKE_CURRENT_BINARY_DIR}
            ${CMAKE_CURRENT_LIST_DIR}/v8ver.cc
            CMAKE_FLAGS -DLINK_LIBRARIES:STRING=${V8_LIBRARIES}
                        -DINCLUDE_DIRECTORIES:STRING=${V8_INCLUDE_DIR}
           RUN_OUTPUT_VARIABLE V8C_OUTPUT)

    IF (NOT (V8C_EXITCODE EQUAL 0))
        MESSAGE(FATAL_ERROR "Failed to build and run program to check V8 version (exit code ${V8C_EXITCODE})")
    ENDIF (NOT (V8C_EXITCODE EQUAL 0))

    IF (V8C_COMPILED)
       SET(V8C_VERSION "${V8C_OUTPUT}")
    ELSE(V8C_COMPILED)
       SET(V8C_VERSION "V8_PRE_3_19_API")
    ENDIF(V8C_COMPILED)
  ENDIF (WIN32)
  MESSAGE(STATUS "Using v8 version: [${V8C_VERSION}]")
  ADD_DEFINITIONS(-D${V8C_VERSION}=1)
ELSE (V8_LIBRARIES)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without V8")
ENDIF (V8_LIBRARIES)

MARK_AS_ADVANCED(V8_INCLUDE_DIR V8_LIBRARIES V8C_VERSION)
