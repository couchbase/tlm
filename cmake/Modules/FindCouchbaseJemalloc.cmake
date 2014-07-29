# Locate jemalloc library
# This module defines
#  JEMALLOC_FOUND, if false, do not try to link with jemalloc
#  JEMALLOC_LIBRARIES, Library path and libs
#  JEMALLOC_INCLUDE_DIR, where to find the ICU headers

FIND_PATH(JEMALLOC_INCLUDE_DIR jemalloc/jemalloc.h
          HINTS
               ENV JEMALLOC_DIR
          PATH_SUFFIXES include
          PATHS
               ~/Library/Frameworks
               /Library/Frameworks
               /opt/local
               /opt/csw
               /opt/jemalloc
               /opt)

FIND_LIBRARY(JEMALLOC_LIBRARIES
             NAMES jemalloc libjemalloc
             HINTS
                 ENV JEMALLOC_DIR
             PATH_SUFFIXES lib
             PATHS
                 ~/Library/Frameworks
                 /Library/Frameworks
                 /opt/local
                 /opt/csw
                 /opt/jemalloc
                 /opt)

IF (JEMALLOC_LIBRARIES)
  SET(JEMALLOC_FOUND true)
  MESSAGE(STATUS "Found jemalloc in ${JEMALLOC_INCLUDE_DIR} : ${JEMALLOC_LIBRARIES}")
ELSE (JEMALLOC_LIBRARIES)
  SET(JEMALLOC_FOUND false)
ENDIF (JEMALLOC_LIBRARIES)

MARK_AS_ADVANCED(JEMALLOC_FOUND JEMALLOC_INCLUDE_DIR JEMALLOC_LIBRARIES)
