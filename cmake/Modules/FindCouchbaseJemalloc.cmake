#
#     Copyright 2018 Couchbase, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Locate jemalloc library
# This module defines
#  JEMALLOC_FOUND, if false, do not try to link with jemalloc
#  JEMALLOC_LIBRARIES, Library path and libs
#  JEMALLOC_INCLUDE_DIR, where to find the jemalloc headers

INCLUDE(CheckFunctionExists)

# Wrap the content of the file to avoid having the
# system log the same information multiple times
# if the file gets included from multiple files
if (NOT DEFINED JEMALLOC_FOUND)
    include(CMakePushCheckState)
    include(CheckSymbolExists)
    include(PlatformIntrospection)

    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_jemalloc_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_jemalloc_exploded ${CMAKE_BINARY_DIR}/tlm/deps/jemalloc.exploded)

    find_path(JEMALLOC_INCLUDE_DIR jemalloc/jemalloc.h
              HINTS ${_jemalloc_exploded}/include
              ${_jemalloc_no_default_path})

    if (NOT JEMALLOC_INCLUDE_DIR)
        message(FATAL_ERROR "Failed to locate jemalloc/jemalloc.h")
    endif ()

    # We need to put _jemalloc_exploded/lib as a hint as we don't
    # install the .lib file to ${CMAKE_INSTALL_PREFIX} on Windows
    find_library(JEMALLOC_LIBRARIES
                 NAMES jemalloc libjemalloc
                 HINTS ${CMAKE_INSTALL_PREFIX}/lib
                 ${_jemalloc_exploded}/lib
                 ${_jemalloc_no_default_path})

    if (NOT JEMALLOC_LIBRARIES)
        message(FATAL_ERROR "Failed to locate jemalloc library")
    endif ()

    message(STATUS "Found jemalloc headers in: ${JEMALLOC_INCLUDE_DIR}")
    message(STATUS "                  library: ${JEMALLOC_LIBRARIES}")

    # Check that the found jemalloc library has it's symbols prefixed with 'je_'
    cmake_push_check_state(RESET)
    set(CMAKE_REQUIRED_LIBRARIES ${JEMALLOC_LIBRARIES})
    set(CMAKE_REQUIRED_INCLUDES ${JEMALLOC_INCLUDE_DIR})
    if (WIN32)
        list(APPEND CMAKE_REQUIRED_INCLUDES ${JEMALLOC_INCLUDE_DIR}/msvc_compat)
    endif ()
    check_symbol_exists(je_malloc "stdbool.h;jemalloc/jemalloc.h" HAVE_JE_SYMBOLS)
    check_symbol_exists(je_sdallocx "stdbool.h;jemalloc/jemalloc.h" HAVE_JEMALLOC_SDALLOCX)
    cmake_pop_check_state()

    if (NOT HAVE_JE_SYMBOLS)
        message(FATAL_ERROR "Found jemalloc in ${JEMALLOC_LIBRARIES}, but was built without 'je_' prefix on symbols so cannot be used.")
    endif ()

    set(JEMALLOC_FOUND true CACHE BOOL "Found jemalloc" FORCE)
    mark_as_advanced(JEMALLOC_FOUND JEMALLOC_INCLUDE_DIR JEMALLOC_LIBRARIES)
endif (NOT DEFINED JEMALLOC_FOUND)
