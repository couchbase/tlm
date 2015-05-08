# Locate tcmalloc library
# This module defines
#  TCMALLOC_FOUND, if false, do not try to link with tcmalloc
#  TCMALLOC_LIBRARIES, Library path and libs
#  TCMALLOC_INCLUDE_DIR, where to find the ICU headers

SET(_gperftools_exploded ${CMAKE_BINARY_DIR}/tlm/deps/gperftools.exploded)

FIND_PATH(TCMALLOC_INCLUDE_DIR gperftools/malloc_hook_c.h
          PATHS
              ${_gperftools_exploded}/include)

IF (TCMALLOC_INCLUDE_DIR)
  IF (WIN32)
    # Debug should use debug libraries, otherwise use Release
    IF (CMAKE_BUILD_TYPE STREQUAL "Debug")
      SET(_build_type "Debug")
      FIND_LIBRARY(TCMALLOC_LIBRARIES
                   NAMES libtcmalloc_minimal-debug
                   PATHS ${_gperftools_exploded}/lib/Debug)
    ELSE (CMAKE_BUILD_TYPE STREQUAL "Debug")
      SET(_build_type "Release")
      FIND_LIBRARY(TCMALLOC_LIBRARIES
                   NAMES libtcmalloc_minimal
                   PATHS ${_gperftools_exploded}/lib/Release)
    ENDIF (CMAKE_BUILD_TYPE STREQUAL "Debug")
  ELSE (WIN32)
    FIND_LIBRARY(TCMALLOC_LIBRARIES
                 NAMES libtcmalloc_minimal-debug
                 PATHS ${_gperftools_exploded}/lib)
  ENDIF (WIN32)
ENDIF (TCMALLOC_INCLUDE_DIR)

IF (TCMALLOC_LIBRARIES)
  SET(TCMALLOC_FOUND true)
  MESSAGE(STATUS "Found tcmalloc in ${TCMALLOC_INCLUDE_DIR} : ${TCMALLOC_LIBRARIES}")
ELSE (TCMALLOC_LIBRARIES)
  SET(TCMALLOC_FOUND false)
ENDIF (TCMALLOC_LIBRARIES)

MARK_AS_ADVANCED(TCMALLOC_FOUND TCMALLOC_INCLUDE_DIR TCMALLOC_LIBRARIES)
