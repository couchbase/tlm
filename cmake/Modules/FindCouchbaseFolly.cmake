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

cb_get_supported_platform(_is_supported_platform)
if (_is_supported_platform)
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

if (CB_THREADSANITIZER)
    find_library(FOLLY_LIBRARIES_UNSANITIZED
                 NAMES folly
                 HINTS ${_folly_exploded}/lib
                 ${_jemalloc_no_default_path})
endif()

# Defines FOLLY_LIBRARY / LIBRARIES to the correct Debug / Release
# lib based on the current BUILD_TYPE
unset(FOLLY_LIBRARY CACHE)
unset(FOLLY_LIBRARIES CACHE)
select_library_configurations(FOLLY)

if (NOT FOLLY_LIBRARIES)
    message(FATAL_ERROR "Failed to locate folly library")
endif ()

if (CB_THREADSANITIZER AND NOT FOLLY_LIBRARIES_UNSANITIZED)
    message(FATAL_ERROR "Failed to locate unsanitized folly library for TSan build")
endif ()

MESSAGE(STATUS "Found Facebook Folly headers: ${FOLLY_CONFIG_INCLUDE_DIR}")
MESSAGE(STATUS "                   libraries: ${FOLLY_LIBRARIES}")
if (FOLLY_LIBRARIES_UNSANITIZED)
    MESSAGE(STATUS "       unsanitized libraries: ${FOLLY_LIBRARIES_UNSANITIZED}")
endif ()

if(NOT DOUBLE_CONVERSION_INCLUDE_DIR OR NOT DOUBLE_CONVERSION_LIBRARIES)
    MESSAGE(FATAL_ERROR "Can't use Folly without double-conversion library")
endif()

set(folly_dependancies ${DOUBLE_CONVERSION_LIBRARIES}
            ${GLOG_LIBRARIES}
            ${CMAKE_DL_LIBS}
            Boost::context
            Boost::filesystem
            Boost::program_options
            Boost::regex
            Boost::system
            Boost::thread
            fmt::fmt
            ${LIBEVENT_LIBRARIES}
            ${OPENSSL_LIBRARIES})
if (APPLE)
    # on macOS we require c++abi for ___cxa_increment_exception_refcount
    # as used by lang/Exception.cpp
    list (APPEND folly_dependancies c++abi)
endif ()

# Define 'modern' CMake targets for Folly for targets to depend on. These
# are simpler than the FOLLY_LIBRARIES / FOLLY_INCLUDE_DIR env vars as
# targets don't have to explicitly add each one.
add_library(Folly::folly STATIC IMPORTED)
set_target_properties(Folly::folly
    PROPERTIES
    IMPORTED_LOCATION ${FOLLY_LIBRARY_RELEASE})
if(FOLLY_LIBRARY_DEBUG)
    set_target_properties(Folly::folly
        PROPERTIES
        IMPORTED_LOCATION_DEBUG ${FOLLY_LIBRARY_DEBUG})
endif()
target_link_libraries(Folly::folly INTERFACE
    Folly::headers
    ${folly_dependancies})

if(FOLLY_LIBRARIES_UNSANITIZED)
    add_library(Folly::folly_unsanitized STATIC IMPORTED)
    set_target_properties(Folly::folly_unsanitized
        PROPERTIES
        IMPORTED_LOCATION ${FOLLY_LIBRARIES_UNSANITIZED})
    target_link_libraries(Folly::folly_unsanitized INTERFACE
        Folly::headers
        ${folly_dependancies})
else()
    add_library(Folly::folly_unsanitized INTERFACE IMPORTED)
    target_link_libraries(Folly::folly_unsanitized INTERFACE Folly::folly)
endif()

# Define an interface library which is just the headers of Folly.
# This is useful as some targets (e.g. tests) only make use of the
# portability headers such as portability/GTest.h
add_library(Folly::headers INTERFACE IMPORTED)
target_include_directories(Folly::headers INTERFACE
        ${FOLLY_CONFIG_INCLUDE_DIR}
        ${Boost_INCLUDE_DIR}
        ${DOUBLE_CONVERSION_INCLUDE_DIR}
        ${GLOG_INCLUDE_DIR})

# Append Folly's depenancies to the include / lib variables so users
# of Folly pickup the dependancies automatically.
list(APPEND FOLLY_INCLUDE_DIR )
set(FOLLY_INCLUDE_DIR
    ${FOLLY_CONFIG_INCLUDE_DIR}
    ${Boost_INCLUDE_DIR}
    ${DOUBLE_CONVERSION_INCLUDE_DIR}
    ${GLOG_INCLUDE_DIR}
    CACHE STRING "Folly include directories" FORCE)

foreach(variant FOLLY_LIBRARIES FOLLY_LIBRARIES_UNSANITIZED)
    list(APPEND ${variant} ${folly_dependancies})
endforeach()

mark_as_advanced(FOLLY_INCLUDE_DIR FOLLY_LIBRARIES)
