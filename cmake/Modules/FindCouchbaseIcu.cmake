# Locate icu4c library
# This module defines
#  ICU_FOUND, if false, do not try to link with ICU
#  ICU_LIBRARIES, Library path and libs
#  ICU_INCLUDE_DIR, where to find the ICU headers

# First check in ${CMAKE_INSTALL_PREFIX} to pickup cbdeps
# before any system packages, fallback to default paths if not found.
FIND_PROGRAM(ICU_CONFIG_EXECUTABLE
             NAMES icu-config
             PATHS ${CMAKE_INSTALL_PREFIX}/bin
             NO_DEFAULT_PATH
             DOC "icu-config executable")
FIND_PROGRAM(ICU_CONFIG_EXECUTABLE
             NAMES icu-config
             PATHS
                /usr/bin
                /usr/local/bin
                ~/bin
             DOC "icu-config executable")
MARK_AS_ADVANCED(ICU_CONFIG_EXECUTABLE)

IF (ICU_CONFIG_EXECUTABLE)
  MESSAGE(STATUS "Found icu-config in ${ICU_CONFIG_EXECUTABLE}")
  EXECUTE_PROCESS(COMMAND ${ICU_CONFIG_EXECUTABLE} --cppflags-searchpath
                  OUTPUT_VARIABLE ICU_INCLUDE_DIR
                  ERROR_QUIET)
  STRING(REGEX REPLACE "^[-/]I" "" ICU_INCLUDE_DIR "${ICU_INCLUDE_DIR}")

  EXECUTE_PROCESS(COMMAND ${ICU_CONFIG_EXECUTABLE} --ldflags-searchpath
                  OUTPUT_VARIABLE ICU_LIB_SEARCHPATH
                  ERROR_QUIET)
  STRING(REGEX REPLACE "^[-/]L" "" ICU_LIB_HINT_DIR "${ICU_LIB_SEARCHPATH}")

  IF (NOT WIN32)
      EXECUTE_PROCESS(COMMAND ${ICU_CONFIG_EXECUTABLE} --ldflags-libsonly
                      OUTPUT_VARIABLE ICU_LIBRARIES
                      ERROR_QUIET)
      IF (ICU_LIBRARIES)
          STRING(STRIP ${ICU_LIBRARIES} ICU_LIBRARIES)
          STRING(STRIP ${ICU_LIB_SEARCHPATH} ICU_LIB_SEARCHPATH)
          SET(ICU_LIB_SEARCHPATH "${ICU_LIB_SEARCHPATH} ${ICU_LIBRARIES}")
	  SET(ICU_LIBRARIES ${ICU_LIB_SEARCHPATH})
      ENDIF(ICU_LIBRARIES)
  ENDIF(NOT WIN32)

ELSE (ICU_CONFIG_EXECUTABLE)
  # Mostly for Windows, where icu-config is not common
  FIND_PATH (ICU_INCLUDE_DIR
    NAMES unicode/utypes.h utypes.h
    PATH_SUFFIXES include
    DOC "Include directories for ICU")
  # Don't set ICU_LIB_HINT_DIR; depend on FIND_LIBRARY() calls below
ENDIF(ICU_CONFIG_EXECUTABLE)


IF (ICU_INCLUDE_DIR)
  STRING(STRIP ${ICU_INCLUDE_DIR} ICU_INCLUDE_DIR)
  STRING(STRIP "${ICU_LIB_HINT_DIR}" ICU_LIB_HINT_DIR)

  IF (NOT ICU_LIBRARIES)
      FIND_LIBRARY(ICU_ICUUC_LIBRARY
                   NAMES icuuc
                   HINTS
                       ENV LUA_DIR
                       ${ICU_LIB_HINT_DIR})

      FIND_LIBRARY(ICU_ICUDATA_LIBRARY
                   NAMES icudata
                   HINTS
                       ENV LUA_DIR
                       ${ICU_LIB_HINT_DIR})

      FIND_LIBRARY(ICU_ICUI18N_LIBRARY
                   NAMES icui18n
                   HINTS
                       ENV LUA_DIR
                       ${ICU_LIB_HINT_DIR})

      FIND_LIBRARY(ICU_ICUCDT_LIBRARY
                   NAMES icucdt
                   HINTS
                       ENV LUA_DIR
                       ${ICU_LIB_HINT_DIR})

      FIND_LIBRARY(ICU_ICUIN_LIBRARY
                   NAMES icuin
                   HINTS
                       ENV LUA_DIR
                       ${ICU_LIB_HINT_DIR})

      IF (ICU_ICUUC_LIBRARY)
          SET(ICU_LIBRARIES ${ICU_LIBRARIES} ${ICU_ICUUC_LIBRARY})
      ENDIF()

      IF(ICU_ICUDATA_LIBRARY)
          SET(ICU_LIBRARIES ${ICU_LIBRARIES} ${ICU_ICUDATA_LIBRARY})
      ENDIF()

      IF(ICU_ICUI18N_LIBRARY)
          SET(ICU_LIBRARIES ${ICU_LIBRARIES} ${ICU_ICUI18N_LIBRARY})
      ENDIF()

      IF(ICU_ICUCDT_LIBRARY)
          SET(ICU_LIBRARIES ${ICU_LIBRARIES} ${ICU_ICUCDT_LIBRARY})
      ENDIF()

      IF(ICU_ICUIN_LIBRARY)
          SET(ICU_LIBRARIES ${ICU_LIBRARIES} ${ICU_ICUIN_LIBRARY})
      ENDIF()
  ENDIF(NOT ICU_LIBRARIES)

  MESSAGE(STATUS "Found ICU headers in ${ICU_INCLUDE_DIR}")
  MESSAGE(STATUS "Using ICU libraries: ${ICU_LIBRARIES}")
ELSE (ICU_INCLUDE_DIR)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without ICU")
ENDIF (ICU_INCLUDE_DIR)

MARK_AS_ADVANCED(ICU_INCLUDE_DIR ICU_LIBRARIES)
