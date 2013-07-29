# Locate snappy library
# This module defines
#  SNAPPY_FOUND, if false, do not try to link with snappy
#  SNAPPY_LIBRARIES, Library path and libs
#  SNAPPY_INCLUDE_DIR, where to find the ICU headers

FIND_PATH(SNAPPY_INCLUDE_DIR snappy.h
          HINTS
               ENV SNAPPY_DIR
          PATH_SUFFIXES include
          PATHS
               ${DEPS_INCLUDE_DIR}
               ~/Library/Frameworks
               /Library/Frameworks
               /opt/local
               /opt/csw
               /opt/snappy
               /opt)

FIND_LIBRARY(SNAPPY_LIBRARIES
             NAMES snappy
             HINTS
                 ENV SNAPPY_DIR
             PATHS
                 ${DEPS_LIB_DIR}
                 ~/Library/Frameworks
                 /Library/Frameworks
                 /opt/local
                 /opt/csw
                 /opt/snappy
                 /opt)

IF (SNAPPY_LIBRARIES)
  SET(SNAPPY_FOUND true)
  MESSAGE(STATUS "Found snappy in ${SNAPPY_INCLUDE_DIR} : ${SNAPPY_LIBRARIES}")
ELSE (SNAPPY_LIBRARIES)
  SET(SNAPPY_FOUND false)
ENDIF (SNAPPY_LIBRARIES)

MARK_AS_ADVANCED(SNAPPY_FOUND SNAPPY_INCLUDE_DIR SNAPPY_LIBRARIES)
