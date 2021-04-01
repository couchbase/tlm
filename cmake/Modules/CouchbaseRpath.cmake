SET(CMAKE_SKIP_BUILD_RPATH FALSE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

# If the system supports it we want to add in $ORIGIN
IF (UNIX)
  IF(APPLE)
    SET (ORIGIN @executable_path)
  ELSE(APPLE)
    SET (ORIGIN \$ORIGIN)
  ENDIF(APPLE)
  SET(RPATH ${ORIGIN}/../lib)
ENDIF()

SET(RPATH "${RPATH};${CMAKE_INSTALL_PREFIX}/lib")
IF ("${CMAKE_INSTALL_RPATH}" STREQUAL "")
ELSE()
  SET(RPATH "${RPATH};${CMAKE_INSTALL_RPATH}")
ENDIF()
SET(CMAKE_INSTALL_RPATH "${RPATH}")

SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# If using GCC, also ensure that we set a BUILD RPATH that includes
# that gcc's libs such as libstdc++.so.
IF ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
  EXECUTE_PROCESS(
    COMMAND "${CMAKE_CXX_COMPILER}" -print-file-name=libstdc++.so
    OUTPUT_VARIABLE _gccfile OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE _errormsg
    RESULT_VARIABLE _failure)
  IF (_failure)
    MESSAGE (FATAL_ERROR "Error (${_failure}) determining path to libstdc++.so: ${_errormsg}")
  ENDIF ()
  GET_FILENAME_COMPONENT (_gccdir "${_gccfile}" DIRECTORY)
  LIST (APPEND CMAKE_BUILD_RPATH "${_gccdir}")
ENDIF()
