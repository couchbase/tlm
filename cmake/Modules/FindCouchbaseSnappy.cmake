# Locate snappy library
# This module defines
#  SNAPPY_FOUND, if false, do not try to link with snappy
#  SNAPPY_LIBRARIES, Library path and libs
#  SNAPPY_INCLUDE_DIR, where to find the ICU headers
SET(_snappy_exploded ${CMAKE_BINARY_DIR}/tlm/deps/snappy.exploded)

FIND_PATH(SNAPPY_INCLUDE_DIR snappy.h
          HINTS
               "${_snappy_exploded}"
               ENV SNAPPY_DIR
          PATH_SUFFIXES include
          PATHS
               ~/Library/Frameworks
               /Library/Frameworks
               /opt/local
               /opt/csw
               /opt/snappy
               /opt)

FIND_LIBRARY(SNAPPY_LIBRARIES
             NAMES snappy
             HINTS
                 "${_snappy_exploded}"
                 ENV SNAPPY_DIR
             PATH_SUFFIXES lib
             PATHS
                 ~/Library/Frameworks
                 /Library/Frameworks
                 /opt/local
                 /opt/csw
                 /opt/snappy
                 /opt)

IF (SNAPPY_LIBRARIES)
  MESSAGE(STATUS "Found snappy in ${SNAPPY_INCLUDE_DIR} : ${SNAPPY_LIBRARIES}")
ELSE (SNAPPY_LIBRARIES)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without Snappy")
ENDIF (SNAPPY_LIBRARIES)

MARK_AS_ADVANCED(SNAPPY_INCLUDE_DIR SNAPPY_LIBRARIES)
