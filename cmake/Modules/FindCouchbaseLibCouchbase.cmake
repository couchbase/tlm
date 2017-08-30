# Locate libcouchbase library
# This module defines
#  LIBCOUCHBASE_FOUND, if false, do not try to link with libcouchbase
#  LIBCOUCHBASE_LIBRARIES, Library path and libs
#  LIBCOUCHBASE_INCLUDE_DIR, where to find the ICU headers
SET(_libcouchbase_exploded ${CMAKE_BINARY_DIR}/tlm/deps/libcouchbase.exploded)

FIND_PATH(LIBCOUCHBASE_INCLUDE_DIR libcouchbase/couchbase.h
          HINTS "${_libcouchbase_exploded}"
          ENV LIBCOUCHBASE_DIR
          PATH_SUFFIXES include)

FIND_LIBRARY(LIBCOUCHBASE_LIBRARIES
             NAMES couchbase
             HINTS "${_libcouchbase_exploded}"
             ENV LIBCOUCHBASE_DIR
             PATH_SUFFIXES lib)

IF (LIBCOUCHBASE_LIBRARIES)
  MESSAGE(STATUS "Found libcouchbase in ${LIBCOUCHBASE_INCLUDE_DIR} : ${LIBCOUCHBASE_LIBRARIES}")
ELSE (LIBCOUCHBASE_LIBRARIES)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without libcouchbase")
ENDIF (LIBCOUCHBASE_LIBRARIES)

MARK_AS_ADVANCED(LIBCOUCHBASE_INCLUDE_DIR LIBCOUCHBASE_LIBRARIES)
