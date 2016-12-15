# Locate jemalloc library
# This module defines
#  JEMALLOC_FOUND, if false, do not try to link with jemalloc
#  JEMALLOC_LIBRARIES, Library path and libs
#  JEMALLOC_INCLUDE_DIR, where to find the ICU headers
INCLUDE (CMakePushCheckState)
INCLUDE (CheckSymbolExists)

SET(_jemalloc_exploded ${CMAKE_BINARY_DIR}/tlm/deps/jemalloc.exploded)

FIND_PATH(JEMALLOC_INCLUDE_DIR jemalloc/jemalloc.h
          HINTS
               ENV JEMALLOC_DIR
          PATH_SUFFIXES include
          PATHS
               ${_jemalloc_exploded}
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
                 ${_jemalloc_exploded}
                 ~/Library/Frameworks
                 /Library/Frameworks
                 /opt/local
                 /opt/csw
                 /opt/jemalloc
                 /opt)

IF (JEMALLOC_INCLUDE_DIR AND JEMALLOC_LIBRARIES)
  # Check that the found jemalloc library has it's symbols prefixed with 'je_'
  CMAKE_PUSH_CHECK_STATE(RESET)
  SET(CMAKE_REQUIRED_LIBRARIES ${JEMALLOC_LIBRARIES})
  SET(CMAKE_REQUIRED_INCLUDES ${JEMALLOC_INCLUDE_DIR})
  IF(WIN32)
    LIST(APPEND CMAKE_REQUIRED_INCLUDES ${JEMALLOC_INCLUDE_DIR}/msvc_compat)
  ENDIF(WIN32)
  CHECK_SYMBOL_EXISTS(je_malloc "stdbool.h;jemalloc/jemalloc.h" HAVE_JE_SYMBOLS)
  CMAKE_POP_CHECK_STATE()

  IF(HAVE_JE_SYMBOLS)
    SET(JEMALLOC_FOUND true)
    MESSAGE(STATUS "Found jemalloc in ${JEMALLOC_INCLUDE_DIR} : ${JEMALLOC_LIBRARIES}")
  ELSE(HAVE_JE_SYMBOLS)
    MESSAGE(FATAL_ERROR "Found jemalloc in ${JEMALLOC_LIBRARIES}, but was built without 'je_' prefix on symbols so cannot be used.")
    MESSAGE("   (Consider installing pre-built package from cbdeps, by adding 'EXTRA_CMAKE_OPTIONS=-DCB_DOWNLOAD_DEPS=1' to make arguments).")
  ENDIF(HAVE_JE_SYMBOLS)
ELSE (JEMALLOC_INCLUDE_DIR AND JEMALLOC_LIBRARIES)
  MESSAGE(FATAL_ERROR "Cannot build Couchbase without jemalloc.")
ENDIF (JEMALLOC_INCLUDE_DIR AND JEMALLOC_LIBRARIES)

MARK_AS_ADVANCED(JEMALLOC_FOUND JEMALLOC_INCLUDE_DIR JEMALLOC_LIBRARIES)
