# Locate Google's double-conversion library (required by Folly).
# This module defines
#  DOUBLE_CONVERSION_FOUND, if false, do not try to use double-conversion
#  DOUBLE_CONVERSION_LIBRARIES, Library path and libs
#  DOUBLE_CONVERSION_INCLUDE_DIR, where to find the headers
if (NOT DEFINED DOUBLE_CONVERSION_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_double_conversion_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_double_conversion_exploded ${CMAKE_BINARY_DIR}/tlm/deps/double-conversion.exploded)

    find_path(DOUBLE_CONVERSION_INCLUDE_DIR double-conversion/double-conversion.h
            PATH_SUFFIXES include
            PATHS ${_double_conversion_exploded}
            ${_double_conversion_no_default_path})

    find_library(DOUBLE_CONVERSION_LIBRARIES
            NAMES double-conversion
            HINTS ${_double_conversion_exploded}/lib
            ${_double_conversion_no_default_path})

    if(DOUBLE_CONVERSION_INCLUDE_DIR AND DOUBLE_CONVERSION_LIBRARIES)
        MESSAGE(STATUS "Found double-conversion headers: ${DOUBLE_CONVERSION_INCLUDE_DIR}")
        MESSAGE(STATUS "                      libraries: ${DOUBLE_CONVERSION_LIBRARIES}")
        set(DOUBLE_CONVERSION_FOUND true CACHE BOOL "Found double-conversion" FORCE)
    else()
        set(DOUBLE_CONVERSION_FOUND false CACHE BOOL "Found double-conversion" FORCE)
    endif()

    mark_as_advanced(DOUBLE_CONVERSION_FOUND DOUBLE_CONVERSION_INCLUDE_DIR DOUBLE_CONVERSION_LIBRARIES)
endif()
