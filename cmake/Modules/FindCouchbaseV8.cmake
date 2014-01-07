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
ELSE (V8_LIBRARIES)
  SET(V8_FOUND false)
ENDIF (V8_LIBRARIES)

MARK_AS_ADVANCED(V8_FOUND V8_INCLUDE_DIR V8_LIBRARIES)
