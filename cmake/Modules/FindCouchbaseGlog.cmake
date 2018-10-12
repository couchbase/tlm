# Locate Google Glog library
# This module defines
#  GLOG_FOUND, if false, do not try to link with glog
#  GLOG_LIBRARIES, Library path and libs
#  GLOG_INCLUDE_DIR, where to find the headers
if (NOT DEFINED GLOG_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_glog_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_glog_exploded ${CMAKE_BINARY_DIR}/tlm/deps/glog.exploded)

    find_path(GLOG_INCLUDE_DIR glog/config.h
            PATH_SUFFIXES include
            PATHS ${_glog_exploded}
            ${_glog_no_default_path})

    find_library(GLOG_LIBRARIES
            NAMES glog
            HINTS ${_glog_exploded}/lib
            ${_glog_no_default_path})

    if(GLOG_INCLUDE_DIR AND GLOG_LIBRARIES)
        MESSAGE(STATUS "Found glog headers: ${GLOG_INCLUDE_DIR}")
        MESSAGE(STATUS "         libraries: ${GLOG_LIBRARIES}")
        set(GLOG_FOUND true CACHE BOOL "Found Google Logging Library (glog)" FORCE)
    else()
        set(GLOG_FOUND false CACHE BOOL "Found Google Logging Library (glog)" FORCE)
    endif()

    mark_as_advanced(GLOG_FOUND GLOG_INCLUDE_DIR GLOG_LIBRARIES)
endif()
