# Locate Google Gflags library
# This module defines
#  GFLAGS_FOUND, if false, do not try to link with gflags
#  GFLAGS_LIBRARIES, Library path and libs
#  GLOG_INCLUDE_DIR, where to find the headers
if (NOT DEFINED GFLAGS_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        set(_gflags_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_gflags_exploded ${CMAKE_BINARY_DIR}/tlm/deps/gflags.exploded)

    find_path(GFLAGS_INCLUDE_DIR gflags/gflags.h
            PATH_SUFFIXES include
            PATHS ${_gflags_exploded}
            ${_gflags_no_default_path})

    find_library(GFLAGS_LIBRARIES
            NAMES gflags gflags_static
            HINTS ${_gflags_exploded}/lib
            ${_gflags_no_default_path})

    if (GFLAGS_INCLUDE_DIR AND GFLAGS_LIBRARIES)
        MESSAGE(STATUS "Found gflags headers: ${GFLAGS_INCLUDE_DIR}")
        MESSAGE(STATUS "           libraries: ${GFLAGS_LIBRARIES}")
        set(GFLAGS_FOUND true CACHE BOOL "Found Google flags Library (gflags)" FORCE)
    else ()
        message(FATAL_ERROR "Can't build Couchbase without gflags")
    endif ()

    mark_as_advanced(GFLAGS_FOUND GFLAGS_INCLUDE_DIR GFLAGS_LIBRARIES)
endif()
