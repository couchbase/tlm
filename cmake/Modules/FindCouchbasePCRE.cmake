# Copyright (C) 2019 Couchbase
#
# Finds the PCRE lib and headers. Only guaranteed to work with the cbdeps
# PCRE package as part of the Couchbase Server build, but it does use
# standard CMake conventions so it may work in other environments as well.
# Sets:
# PCRE_INCLUDE_DIR
# PCRE_LIBRARY_DIR
#
# Important: the PCRE cbdep package is only expected to work with CGo.
# Linking it to MSVC-compiled C/C++ code will likely not work due to the
# absence of the .lib link library. See comment further down.

IF (NOT DEFINED PCRE_FOUND)

  # Supported platforms should only use the provided hints
  CB_GET_SUPPORTED_PLATFORM (_is_supported_platform)
  IF (_is_supported_platform)
    SET (_no_default_path NO_DEFAULT_PATH)
  ENDIF ()

  SET (_exploded_dir "${CMAKE_BINARY_DIR}/tlm/deps/pcre.exploded")

  FIND_PATH (PCRE_INCLUDE_DIR
    NAMES pcre.h
    HINTS "${_exploded_dir}"
    PATH_SUFFIXES include
    ${_no_default_path})

  # I am theorizing a bit here, but: On Windows I do not believe we can use
  # FIND_LIBRARY() here. This is because PCRE was built using MinGW (due to
  # insurmountable problems getting it to compile correctly in MSVC), but
  # our overall Server CMake project is in "MSVC Mode" and hence is expecting
  # to "find" a pcre.lib link library for building. No such library is produced
  # by MinGW, and while there is some evidence that it can be convinced to do
  # so, the doc I've been able to find online left me too confused to try.
  # Moreover, since PCRE is only actually linked by Go code in our project
  # (which uses MinGW under the covers anyway), we never actually NEED the
  # .lib file; all we need is the path to the directory containing libpcre.dll.
  # There is extensive confusing commentary about this on MB-32895.
  FIND_PATH (PCRE_LIBRARY_DIR
    NAMES libpcre.dll libpcre.so libpcre.dylib
    HINTS "${CMAKE_INSTALL_PREFIX}/bin" "${CMAKE_INSTALL_PREFIX}/lib"
    ${_no_default_path})

  INCLUDE (FindPackageHandleStandardArgs)
  FIND_PACKAGE_HANDLE_STANDARD_ARGS (PCRE DEFAULT_MSG PCRE_LIBRARY_DIR PCRE_INCLUDE_DIR)

  IF (PCRE_FOUND)
    MESSAGE (STATUS "PCRE header dir: ${PCRE_INCLUDE_DIR}")
    MESSAGE (STATUS "PCRE library dir: ${PCRE_LIBRARY_DIR}")
  ELSE (PCRE_FOUND)
    MESSAGE (FATAL_ERROR "PCRE is required for building Couchbase, but was not found")
  ENDIF (PCRE_FOUND)

  MARK_AS_ADVANCED (PCRE_INCLUDE_DIR PCRE_LIBRARY PCRE_LIBRARY_DIR PCRE_LIBRARIES)

ENDIF (NOT DEFINED PCRE_FOUND)
