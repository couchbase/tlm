# Locate libuv library
# This module defines
#  LIBUV_FOUND, if false, do not try to link with libuv
#  LIBUV_LIBRARIES, Library path and libs
#  LIBUV_INCLUDE_DIR, where to find the ICU headers
SET(_libuv_exploded ${CMAKE_BINARY_DIR}/tlm/deps/libuv.exploded)

FIND_PATH(LIBUV_INCLUDE_DIR uv.h
          HINTS "${_libuv_exploded}"
          ENV LIBUV_DIR
          PATH_SUFFIXES include)

FIND_LIBRARY(LIBUV_LIBRARIES
          NAMES uv
          HINTS "${_libuv_exploded}"
          ENV LIBUV_DIR
          PATH_SUFFIXES lib)

IF (LIBUV_LIBRARIES)
  MESSAGE(STATUS "Found libuv in ${LIBUV_INCLUDE_DIR} : ${LIBUV_LIBRARIES}")
ELSE (LIBUV_LIBRARIES)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without libuv")
ENDIF (LIBUV_LIBRARIES)

MARK_AS_ADVANCED(LIBUV_INCLUDE_DIR LIBUV_LIBRARIES)
