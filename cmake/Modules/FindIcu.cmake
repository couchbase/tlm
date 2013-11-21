# Locate icu4c library
# This module defines
#  ICU_FOUND, if false, do not try to link with ICU
#  ICU_LIBRARIES, Library path and libs
#  ICU_INCLUDE_DIR, where to find the ICU headers

FIND_PROGRAM(ICU_CONFIG_EXECUTABLE
             NAMES icu-config
             PATHS
                /usr/bin
                /usr/local/bin
                ~/bin
             DOC "icu-config executable")
MARK_AS_ADVANCED(ICU_CONFIG_EXECUTABLE)

IF (ICU_CONFIG_EXECUTABLE)
  EXECUTE_PROCESS(COMMAND ${ICU_CONFIG_EXECUTABLE} --cppflags-searchpath
                  OUTPUT_VARIABLE ICU_INCLUDE_DIR
                  ERROR_QUIET)
  STRING(REGEX REPLACE "^[-/]I" "" ICU_INCLUDE_DIR "${ICU_INCLUDE_DIR}")

  EXECUTE_PROCESS(COMMAND ${ICU_CONFIG_EXECUTABLE} --ldflags-searchpath
                  OUTPUT_VARIABLE ICU_LIB_SEARCHPATH
                  ERROR_QUIET)
  STRING(REGEX REPLACE "^[-/]L" "" ICU_LIB_DIR "${ICU_LIB_SEARCHPATH}")

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
ENDIF(ICU_CONFIG_EXECUTABLE)

IF (WIN32)
  # @TODO fix me!!!
  SET(ICU_INCLUDE_DIR /compile/couchbase/deps/include)
  SET(ICU_LIB_DIR /compile/couchbase/deps/lib)
ENDIF(WIN32)


IF (ICU_INCLUDE_DIR)
  STRING(STRIP ${ICU_INCLUDE_DIR} ICU_INCLUDE_DIR)
  STRING(STRIP ${ICU_LIB_DIR} ICU_LIB_DIR)

  IF (NOT ICU_LIBRARIES)
      FIND_LIBRARY(ICU_ICUUC_LIBRARY
                   NAMES icuuc
                   HINTS
                       ENV LUA_DIR
                   PATHS
                       ${ICU_LIB_DIR})

      FIND_LIBRARY(ICU_ICUDATA_LIBRARY
                   NAMES icudata
                   HINTS
                       ENV LUA_DIR
                   PATHS
                       ${ICU_LIB_DIR})

      FIND_LIBRARY(ICU_ICUI18N_LIBRARY
                   NAMES icui18n
                   HINTS
                       ENV LUA_DIR
                   PATHS
                       ${ICU_LIB_DIR})

      FIND_LIBRARY(ICU_ICUCDT_LIBRARY
                   NAMES icucdt
                   HINTS
                       ENV LUA_DIR
                   PATHS
                       ${ICU_LIB_DIR})

      FIND_LIBRARY(ICU_ICUIN_LIBRARY
                   NAMES icuin
                   HINTS
                       ENV LUA_DIR
                   PATHS
                       ${ICU_LIB_DIR})

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

  SET(ICU_FOUND true)
  MESSAGE(STATUS "Found ICU headers in ${ICU_INCLUDE_DIR}")
  MESSAGE(STATUS "Found ICU libraries in ${ICU_LIB_DIR}")
  MESSAGE(STATUS "Using ICU libraries: ${ICU_LIBRARIES}")
ELSE (ICU_INCLUDE_DIR)
  SET(ICU_FOUND false)
ENDIF (ICU_INCLUDE_DIR)

MARK_AS_ADVANCED(ICU_FOUND ICU_INCLUDE_DIR ICU_LIBRARIES)
