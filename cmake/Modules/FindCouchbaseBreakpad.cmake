# Locate breakpad library
# This module defines
#  BREAKPAD_FOUND, if false, do not try to link with breakpad
#  BREAKPAD_LIBRARIES, Library path and libs
#  BREAKPAD_INCLUDE_DIR, where to find the ICU headers
#  MINIDUMP2CORE, program to generate a corefile from the minidump (UNIX only)

STRING(TOLOWER ${CMAKE_SYSTEM_NAME} LCASE_SYSTEM)

IF (${LCASE_SYSTEM} STREQUAL "sunos")
  SET(LCASE_SYSTEM "solaris")
ENDIF (${LCASE_SYSTEM} STREQUAL "sunos")

SET(_breakpad_exploded ${CMAKE_BINARY_DIR}/tlm/deps/breakpad.exploded)

FIND_PATH(BREAKPAD_INCLUDE_DIR client/${LCASE_SYSTEM}/handler/exception_handler.h
          HINTS ${_breakpad_exploded}/include
          PATH_SUFFIXES breakpad)
IF (WIN32)

  # RelWithDebInfo & MinSizeRel should use the Release libraries, otherwise use
  # the same directory as the build type.
  IF(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    SET(_build_type "Release")
  ELSE(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    SET(_build_type ${CMAKE_BUILD_TYPE})
  ENDIF(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")

  FIND_LIBRARY(BREAKPAD_EXCEPTION_HANDLER_LIBRARY
               NAMES exception_handler
               PATHS ${_breakpad_exploded}/lib/${_build_type})

  FIND_LIBRARY(BREAKPAD_CRASH_GENERATION_LIBRARY
               NAMES crash_generation_client
               PATHS ${_breakpad_exploded}/lib/${_build_type})

  FIND_LIBRARY(BREAKPAD_COMMON_LIBRARY
               NAMES common
               PATHS ${_breakpad_exploded}/lib/${_build_type})

  SET(BREAKPAD_LIBRARIES ${BREAKPAD_EXCEPTION_HANDLER_LIBRARY} ${BREAKPAD_CRASH_GENERATION_LIBRARY} ${BREAKPAD_COMMON_LIBRARY})

  # not used, just set to simplify the test below
  SET(MINIDUMP2CORE true)

ELSE (WIN32)
  FIND_LIBRARY(BREAKPAD_LIBRARIES
               NAMES breakpad_client
               HINTS ${_breakpad_exploded}/lib)

  FIND_PROGRAM(MINIDUMP2CORE minidump-2-core HINTS ${_breakpad_exploded}/bin)
  IF (MINIDUMP2CORE)
     MESSAGE(STATUS "Found minidump-2-core: ${MINIDUMP2CORE}")
  ENDIF (MINIDUMP2CORE)
ENDIF (WIN32)



IF (BREAKPAD_LIBRARIES AND BREAKPAD_INCLUDE_DIR AND MINIDUMP2CORE)
  SET(BREAKPAD_FOUND true)
  MESSAGE(STATUS "Found breakpad in ${BREAKPAD_INCLUDE_DIR} : ${BREAKPAD_LIBRARIES}")
ELSE (BREAKPAD_LIBRARIES AND BREAKPAD_INCLUDE_DIR AND MINIDUMP2CORE)
  SET(BREAKPAD_FOUND false)
  SET(BREAKPAD_LIBRARIES "")
  # For production, supported platforms we require Breakpad.
  GET_SUPPORTED_PRODUCTION_PLATFORM(_supported_platform)
  IF (_supported_platform)
     MESSAGE(FATAL_ERROR "Breakpad not found (required on supported production platform '${_supported_platform}').")
  ELSE (_supported_platform)
     MESSAGE(STATUS "Breakpad not found (optional on non-production platforms)")
  ENDIF (_supported_platform)
ENDIF (BREAKPAD_LIBRARIES AND BREAKPAD_INCLUDE_DIR AND MINIDUMP2CORE)

MARK_AS_ADVANCED(BREAKPAD_FOUND BREAKPAD_INCLUDE_DIR BREAKPAD_LIBRARIES MINIDUMP2CORE)
