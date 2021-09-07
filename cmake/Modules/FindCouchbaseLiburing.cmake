# Locate liburing
# This module defines
#  LIBURING_LIBRARIES, Library path and libs
#  LIBURING_INCLUDE_DIR, where to find the headers
#  LIBURING_FOUND, whether it was found or not
if (NOT DEFINED LIBURING_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_is_supported_platform)
    if (_is_supported_platform)
        set(_liburing_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_liburing_include_dir ${CMAKE_BINARY_DIR}/tlm/deps/liburing.exploded/include)
    set(_liburing_library_dir ${CMAKE_INSTALL_PREFIX}/lib)

    find_path(LIBURING_INCLUDE_DIR liburing.h
              HINTS ${_liburing_include_dir}
              ${_liburing_no_default_path})

    find_library(LIBURING_LIBRARIES
                 NAMES uring
                 HINTS ${_liburing_library_dir}
                 ${_liburing_no_default_path})

    if (LIBURING_INCLUDE_DIR AND LIBURING_LIBRARIES)
        message(STATUS "Found liburing headers in: ${LIBURING_INCLUDE_DIR}")
        message(STATUS "Found liburing library   : ${LIBURING_LIBRARIES}")
        set(LIBURING_FOUND true CACHE BOOL "Found liburing" FORCE)
    else ()
        message(STATUS "Did not find liburing")
        set(liburing_FOUND false CACHE BOOL "Found liburing" FORCE)
    endif ()
endif (NOT DEFINED LIBURING_FOUND)
