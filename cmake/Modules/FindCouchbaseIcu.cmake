# Locate icu4c library
# This module defines
#  ICU_FOUND, if false, do not try to link with ICU
#  ICU_LIBRARIES, Library path and libs
#  ICU_INCLUDE_DIR, where to find the ICU headers
SET(_icu_exploded ${CMAKE_BINARY_DIR}/tlm/deps/icu4c.exploded)

FIND_PATH(ICU_INCLUDE_DIR unicode/utypes.h
          HINTS
              ENV ICU_DIR
          PATH_SUFFIXES include
          PATHS
               ${_icu_exploded})

IF (ICU_INCLUDE_DIR)
  STRING(STRIP ${ICU_INCLUDE_DIR} ICU_INCLUDE_DIR)
  STRING(STRIP "${ICU_LIB_HINT_DIR}" ICU_LIB_HINT_DIR)

  IF (NOT ICU_LIBRARIES)
      SET(_icu_libraries "icuuc;icudata;icui18n;icucdt;icuin")
      FOREACH(_mylib ${_icu_libraries})
         UNSET(_the_lib CACHE)
         FIND_LIBRARY(_the_lib
                      NAMES ${_mylib}
                      HINTS ${ICU_LIB_HINT_DIR})
         IF (_the_lib)
            list(APPEND ICU_LIBRARIES ${_the_lib})
         ENDIF (_the_lib)
      ENDFOREACH(_mylib)
  ENDIF(NOT ICU_LIBRARIES)

  MESSAGE(STATUS "Found ICU headers in ${ICU_INCLUDE_DIR}")
  MESSAGE(STATUS "Using ICU libraries: ${ICU_LIBRARIES}")
ELSE (ICU_INCLUDE_DIR)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without ICU")
ENDIF (ICU_INCLUDE_DIR)

MARK_AS_ADVANCED(ICU_INCLUDE_DIR ICU_LIBRARIES)
