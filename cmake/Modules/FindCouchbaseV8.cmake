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
               ${DEPS_INCLUDE_DIR}
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
                 ${DEPS_LIB_DIR}
                 ~/Library/Frameworks
                 /Library/Frameworks
                 /opt/local
                 /opt/csw
                 /opt/v8
                 /opt)

IF (V8_LIBRARIES)
  SET(V8_FOUND true)
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
    IF (V8C_COMPILED)
       SET(V8C_VERSION "${V8C_OUTPUT}")
    ELSE(V8C_COMPILED)
       SET(V8C_VERSION "V8_PRE_3_19_API")
    ENDIF(V8C_COMPILED)
  ENDIF (WIN32)
  MESSAGE(STATUS "Using v8 version: [${V8C_VERSION}]")
  ADD_DEFINITIONS(-D${V8C_VERSION}=1)
ELSE (V8_LIBRARIES)
  SET(V8_FOUND false)
ENDIF (V8_LIBRARIES)

MARK_AS_ADVANCED(V8_FOUND V8_INCLUDE_DIR V8_LIBRARIES V8C_VERSION)
