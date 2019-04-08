# Locate Facebook's Folly library
# This module defines
#  FOLLY_FOUND, if false, do not try to link with folly
#  FOLLY_LIBRARIES, Library path and libs
#  FOLLY_INCLUDE_DIR, where to find the headers

# Folly required dependancies:
INCLUDE(FindCouchbaseDoubleConversion)
INCLUDE(FindCouchbaseGlog)

if (NOT DEFINED FOLLY_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_folly_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_folly_exploded ${CMAKE_BINARY_DIR}/tlm/deps/folly.exploded)

    find_path(FOLLY_INCLUDE_DIR folly/folly-config.h
            PATH_SUFFIXES include
            PATHS ${_folly_exploded}
            ${_folly_no_default_path})

    # Somebody working on folly decided to add a template parameter to
    # SharedMutex that defaults to whether or not folly was compiled with or
    # without TSan. This is a pain for us because we will need different symbols
    # based on whether or not we are compiling with TSan. If we generally use
    # TSan on a given platform then we should have created an additional
    # library named 'libfollytsan.a' that we should link against instead of the
    # normal library 'libfolly.a' if we are building with TSan enabled.
    if(CB_THREADSANITIZER)
        set(folly_lib follytsan)
    else(CB_THREADSANITIZER)
        set(folly_lib folly)
    endif(CB_THREADSANITIZER)

    find_library(FOLLY_LIBRARIES
            NAMES ${folly_lib}
            HINTS ${_folly_exploded}/lib
            ${_folly_no_default_path})

    if(FOLLY_INCLUDE_DIR AND FOLLY_LIBRARIES)
        MESSAGE(STATUS "Found Facebook Folly headers: ${FOLLY_INCLUDE_DIR}")
        MESSAGE(STATUS "                   libraries: ${FOLLY_LIBRARIES}")

        if(NOT DOUBLE_CONVERSION_INCLUDE_DIR OR NOT DOUBLE_CONVERSION_LIBRARIES)
            MESSAGE(FATAL_ERROR "Can't use Folly without double-conversion library")
        endif()

        # Append Folly's depenancies to the include / lib variables so users
        # of Folly pickup the dependancies automatically.
        list(APPEND FOLLY_INCLUDE_DIR ${DOUBLE_CONVERSION_INCLUDE_DIR} ${GLOG_INCLUDE_DIR})
        set(FOLLY_INCLUDE_DIR ${FOLLY_INCLUDE_DIR} CACHE STRING "Folly include directories" FORCE)

        list(APPEND FOLLY_LIBRARIES
                ${DOUBLE_CONVERSION_LIBRARIES}
                ${GLOG_LIBRARIES}
                ${CMAKE_DL_LIBS}
                ${Boost_SYSTEM_LIBRARY}
                ${Boost_THREAD_LIBRARY})
        set(FOLLY_LIBRARIES ${FOLLY_LIBRARIES} CACHE STRING "Folly libraries" FORCE)

        set(FOLLY_FOUND true CACHE BOOL "Found Facebook Folly" FORCE)
    else()
        set(FOLLY_FOUND false CACHE BOOL "Found Facebook Folly" FORCE)
        MESSAGE(FATAL_ERROR "Can't build Couchbase without Facebook Folly")
    endif()

    mark_as_advanced(FOLLY_FOUND FOLLY_INCLUDE_DIR FOLLY_LIBRARIES)
endif()
