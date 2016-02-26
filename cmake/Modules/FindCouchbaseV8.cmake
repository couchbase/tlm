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
               /opt/v8/include
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
                 /opt/v8/lib
                 /opt)

IF (V8_LIBRARIES)
  MESSAGE(STATUS "Found v8 in ${V8_INCLUDE_DIR} : ${V8_LIBRARIES}")
ELSE (V8_LIBRARIES)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without V8")
ENDIF (V8_LIBRARIES)

MARK_AS_ADVANCED(V8_INCLUDE_DIR V8_LIBRARIES)
