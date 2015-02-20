# Locate icu4c library
# This module defines
#  ICU_FOUND, if false, do not try to link with ICU
#  ICU_LIBRARIES, Library path and libs
#  ICU_INCLUDE_DIR, where to find the ICU headers

FIND_PROGRAM(ICU_CONFIG_EXECUTABLE
             NAMES icu-config
             HINTS ${CMAKE_INSTALL_PREFIX}/bin
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
                      OUTPUT_VARIABLE _icu_libraries
                      ERROR_QUIET)

      IF (_icu_libraries)
          STRING(STRIP ${_icu_libraries} icu_libraries)
          STRING(REPLACE "-l" "" _icu_libraries ${icu_libraries})
          STRING(REPLACE " " ";" _icu_libraries ${_icu_libraries})

          FOREACH(_mylib ${_icu_libraries})
             UNSET(_the_lib CACHE)
             FIND_LIBRARY(_the_lib
                          NAMES ${_mylib}
                          HINTS ${ICU_LIB_HINT_DIR})
             IF (_the_lib)
                LIST(APPEND ICU_LIBRARIES ${_the_lib})
             ELSE (_the_lib)
                MESSAGE(FATAL_ERROR "Failed to locate ${_mylib}")
             ENDIF (_the_lib)
          ENDFOREACH(_mylib)
      ENDIF(_icu_libraries)
  ENDIF(NOT WIN32)
ELSE (ICU_CONFIG_EXECUTABLE)
  # Mostly for Windows, where icu-config is not common
  FIND_PATH(ICU_INCLUDE_DIR
            NAMES unicode/utypes.h utypes.h
            PATH_SUFFIXES include
            DOC "Include directories for ICU")
  # Don't set ICU_LIB_HINT_DIR; depend on FIND_LIBRARY() calls below
ENDIF(ICU_CONFIG_EXECUTABLE)


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
