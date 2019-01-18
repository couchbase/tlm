# Copyright (C) 2019 Couchbase
#
# Finds the PCRE lib and headers. Only guaranteed to work with the cbdeps
# PCRE package as part of the Couchbase Server build, but it does use
# standard CMake conventions so it may work in other environments as well.
# Sets:
# PCRE_INCLUDE_DIR
# PCRE_LIBRARY
# PCRE_LIBRARIES (not fully implemented, only includes libpcre.so)
# PCRE_LIBRARY_DIR

IF (NOT DEFINED PCRE_FOUND)

  # Supported platforms should only use the provided hints
  CB_GET_SUPPORTED_PLATFORM (_supported_platform)
  IF (_supported_platform)
    SET (_no_default_path NO_DEFAULT_PATH)
  ENDIF ()

  SET (_exploded_dir "${CMAKE_BINARY_DIR}/tlm/deps/pcre.exploded")

  FIND_PATH (PCRE_INCLUDE_DIR
    NAMES pcre.h
    PATHS "${_exploded_dir}"
    PATH_SUFFIXES include
    ${_no_default_path})

  FIND_LIBRARY (PCRE_LIBRARY
    NAMES pcre
    PATHS "${_exploded_dir}"
    PATH_SUFFIXES lib
    ${_no_default_path})

  INCLUDE (FindPackageHandleStandardArgs)
  FIND_PACKAGE_HANDLE_STANDARD_ARGS (PCRE DEFAULT_MSG PCRE_LIBRARY PCRE_INCLUDE_DIR)

  IF (PCRE_FOUND)
	SET (PCRE_LIBRARIES ${PCRE_LIBRARY})
    GET_FILENAME_COMPONENT (PCRE_LIBRARY_DIR "${PCRE_LIBRARY}" DIRECTORY)
    MESSAGE (STATUS "PCRE library dir: ${PCRE_LIBRARY_DIR}")
  ELSE (PCRE_FOUND)
    SET (PCRE_LIBRARIES)
    SET (PCRE_LIBRARY_DIR)
  ENDIF (PCRE_FOUND)

  MARK_AS_ADVANCED (PCRE_INCLUDE_DIR PCRE_LIBRARY PCRE_LIBRARY_DIR PCRE_LIBRARIES)

ENDIF (NOT DEFINED PCRE_FOUND)
