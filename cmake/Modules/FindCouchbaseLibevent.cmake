# Locate libevent library
# This module defines
#  LIBEVENT_FOUND, if false, do not try to link with libevent
#  LIBEVENT_LIBRARIES, Library path and libs
#  LIBEVENT_INCLUDE_DIR, where to find the ICU headers

FIND_PATH(LIBEVENT_INCLUDE_DIR evutil.h
          HINTS
               ENV LIBEVENT_DIR
          PATH_SUFFIXES include
          PATHS
               ${DEPS_INCLUDE_DIR}
               ~/Library/Frameworks
               /Library/Frameworks
               /opt/local
               /opt/csw
               /opt/libevent
               /opt)

FIND_LIBRARY(LIBEVENT_LIBRARIES
             NAMES event_core libevent_core
             HINTS
                 ENV LIBEVENT_DIR
             PATHS
                 ${DEPS_LIB_DIR}
                 ~/Library/Frameworks
                 /Library/Frameworks
                 /opt/local
                 /opt/csw
                 /opt/libevent
                 /opt)

IF (LIBEVENT_LIBRARIES)
  MESSAGE(STATUS "Found libevent in ${LIBEVENT_INCLUDE_DIR} : ${LIBEVENT_LIBRARIES}")
ELSE (LIBEVENT_LIBRARIES)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without libevent'")
ENDIF (LIBEVENT_LIBRARIES)

MARK_AS_ADVANCED(LIBEVENT_INCLUDE_DIR LIBEVENT_LIBRARIES)
