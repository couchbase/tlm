# Locate v8 library
# This module defines
#  V8_FOUND, if false, do not try to link with v8
#  V8_LIBRARIES, Library path and libs
#  V8_INCLUDE_DIR, where to find V8 headers

SET(_v8_exploded ${CMAKE_BINARY_DIR}/tlm/deps/v8.exploded)

# V8 inlcudes libplatform/libplatform.h which includes another header as
# `#include <include/v8-platform.h>`. To allow this inclusion we are setting
# V8_INCLUDE_DIR path up until include directory
FIND_PATH(V8_INCLUDE_DIR include/v8.h
          HINTS ${_v8_exploded}
          NO_CMAKE_PATH
          NO_CMAKE_ENVIRONMENT_PATH)

IF (WIN32)
  # RelWithDebInfo & MinSizeRel should use the Release libraries, otherwise use
  # the same directory as the build type.
  IF(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    SET(_build_type "Release")
  ELSE()
    SET(_build_type ${CMAKE_BUILD_TYPE})
  ENDIF()

  FIND_LIBRARY(V8_SHAREDLIB
               NAMES v8.dll
               HINTS ${_v8_exploded}/lib/${_build_type})
  FIND_LIBRARY(V8_PLATFORMLIB
               NAMES v8_libplatform
               HINTS ${_v8_exploded}/archive/${_build_type})
  FIND_LIBRARY(V8_BASELIB
               NAMES v8_libbase
               HINTS ${_v8_exploded}/archive/${_build_type})
  SET(V8_LIBRARIES ${V8_SHAREDLIB} ${V8_PLATFORMLIB} ${V8_BASELIB} winmm)
ELSE (WIN32)
  FIND_LIBRARY(V8_LIBRARIES
               NAMES v8
               HINTS ${CMAKE_INSTALL_PREFIX}/lib)
ENDIF (WIN32)

IF (V8_LIBRARIES)
  MESSAGE(STATUS "Found v8 in ${V8_INCLUDE_DIR} : ${V8_LIBRARIES}")
ELSE (V8_LIBRARIES)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without V8")
ENDIF (V8_LIBRARIES)

MARK_AS_ADVANCED(V8_INCLUDE_DIR V8_LIBRARIES)
