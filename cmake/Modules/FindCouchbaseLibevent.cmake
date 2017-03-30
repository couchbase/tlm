# Locate libevent library
# This module defines
#  LIBEVENT_FOUND, if false, do not try to link with libevent
#  LIBEVENT_LIBRARIES, Library path and libs
#  LIBEVENT_INCLUDE_DIR, where to find the ICU headers

SET(_libevent_exploded ${CMAKE_BINARY_DIR}/tlm/deps/libevent.exploded)

FIND_PATH(LIBEVENT_INCLUDE_DIR event2/event.h
          HINTS ${_libevent_exploded}/include)

FIND_LIBRARY(LIBEVENT_CORE_LIB
             NAMES event_core libevent_core
             HINTS ${CMAKE_INSTALL_PATH}/lib)

FIND_LIBRARY(LIBEVENT_EXTRA_LIB
             NAMES event_extra
             HINTS ${CMAKE_INSTALL_PATH}/lib)

IF (LIBEVENT_INCLUDE_DIR AND LIBEVENT_CORE_LIB)
  MESSAGE(STATUS "Found libevent headers in: ${LIBEVENT_INCLUDE_DIR}")
  MESSAGE(STATUS "                     core: ${LIBEVENT_CORE_LIB}")
  MESSAGE(STATUS "                    extra: ${LIBEVENT_EXTRA_LIB}")
ELSE (LIBEVENT_INCLUDE_DIR AND LIBEVENT_CORE_LIB)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without libevent'")
ENDIF (LIBEVENT_INCLUDE_DIR AND LIBEVENT_CORE_LIB)

SET(LIBEVENT_LIBRARIES "${LIBEVENT_CORE_LIB}")
MARK_AS_ADVANCED(LIBEVENT_INCLUDE_DIR
  LIBEVENT_LIBRARIES
  LIBEVENT_CORE_LIB
  LIBEVENT_EXTRA_LIB)
