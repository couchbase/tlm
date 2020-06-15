# Locate Facebook's Folly library
# This module defines
#  FOLLY_FOUND, if false, do not try to link with folly
#  FOLLY_LIBRARIES, Library path and libs
#  FOLLY_INCLUDE_DIR, where to find the headers

# Folly required dependancies:
INCLUDE(FindCouchbaseDoubleConversion)
INCLUDE(FindCouchbaseGlog)
INCLUDE(FindCouchbaseLibevent)
INCLUDE(FindCouchbaseOpenSSL)

include(PlatformIntrospection)
include(SelectLibraryConfigurations)

cb_get_supported_platform(_supported_platform)
if (_supported_platform)
    # Supported platforms should only use the provided hints and pick it up
    # from cbdeps
    set(_folly_no_default_path NO_DEFAULT_PATH)
endif ()

set(_folly_exploded ${CMAKE_BINARY_DIR}/tlm/deps/folly.exploded)

find_path(FOLLY_CONFIG_INCLUDE_DIR folly/folly-config.h
          PATH_SUFFIXES include
          PATHS ${_folly_exploded}
          ${_folly_no_default_path})

if (NOT FOLLY_CONFIG_INCLUDE_DIR)
    message(FATAL_ERROR "Failed to locate folly include directory")
endif ()

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

find_library(FOLLY_LIBRARY_RELEASE
             NAMES ${folly_lib}
             HINTS ${_folly_exploded}/lib
             ${_folly_no_default_path})

find_library(FOLLY_LIBRARY_DEBUG
             NAMES follyd
             HINTS ${_folly_exploded}/lib
             ${_jemalloc_no_default_path})

# Defines FOLLY_LIBRARY / LIBRARIES to the correct Debug / Release
# lib based on the current BUILD_TYPE
unset(FOLLY_LIBRARY CACHE)
unset(FOLLY_LIBRARIES CACHE)
select_library_configurations(FOLLY)

if (NOT FOLLY_LIBRARIES)
    message(FATAL_ERROR "Failed to locate folly library")
endif ()

MESSAGE(STATUS "Found Facebook Folly headers: ${FOLLY_CONFIG_INCLUDE_DIR}")
MESSAGE(STATUS "                   libraries: ${FOLLY_LIBRARIES}")

if(NOT DOUBLE_CONVERSION_INCLUDE_DIR OR NOT DOUBLE_CONVERSION_LIBRARIES)
    MESSAGE(FATAL_ERROR "Can't use Folly without double-conversion library")
endif()

# Append Folly's depenancies to the include / lib variables so users
# of Folly pickup the dependancies automatically.
list(APPEND FOLLY_INCLUDE_DIR )
set(FOLLY_INCLUDE_DIR ${FOLLY_CONFIG_INCLUDE_DIR} ${DOUBLE_CONVERSION_INCLUDE_DIR} ${GLOG_INCLUDE_DIR}
    CACHE STRING "Folly include directories" FORCE)

list(APPEND FOLLY_LIBRARIES
            ${DOUBLE_CONVERSION_LIBRARIES}
            ${GLOG_LIBRARIES}
            ${CMAKE_DL_LIBS}
            Boost::context
            Boost::filesystem
            Boost::program_options
            Boost::regex
            Boost::system
            Boost::thread
            ${LIBEVENT_LIBRARIES}
            ${OPENSSL_LIBRARIES})

mark_as_advanced(FOLLY_INCLUDE_DIR FOLLY_LIBRARIES)
