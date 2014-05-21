# Locate tcmalloc library
# This module defines
#  TCMALLOC_FOUND, if false, do not try to link with tcmalloc
#  TCMALLOC_LIBRARIES, Library path and libs
#  TCMALLOC_INCLUDE_DIR, where to find the ICU headers

FIND_PATH(TCMALLOC_INCLUDE_DIR gperftools/malloc_hook_c.h
          HINTS
               ENV TCMALLOC_DIR
          PATH_SUFFIXES include
          PATHS
               ~/Library/Frameworks
               /Library/Frameworks
               /opt/local
               /opt/csw
               /opt/tcmalloc
               /opt)

FIND_LIBRARY(TCMALLOC_LIBRARIES
             NAMES tcmalloc_minimal libtcmalloc_minimal
             HINTS
                 ENV TCMALLOC_DIR
             PATHS
                 ~/Library/Frameworks
                 /Library/Frameworks
                 /opt/local
                 /opt/csw
                 /opt/tcmalloc
                 /opt)

IF (TCMALLOC_LIBRARIES)
  SET(TCMALLOC_FOUND true)
  MESSAGE(STATUS "Found tcmalloc in ${TCMALLOC_INCLUDE_DIR} : ${TCMALLOC_LIBRARIES}")
  ADD_DEFINITIONS(-DHAVE_TCMALLOC)
ELSE (TCMALLOC_LIBRARIES)
  SET(TCMALLOC_FOUND false)
ENDIF (TCMALLOC_LIBRARIES)

MARK_AS_ADVANCED(TCMALLOC_FOUND TCMALLOC_INCLUDE_DIR TCMALLOC_LIBRARIES)
