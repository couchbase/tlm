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

# Locate snappy library
# This module defines
#  SNAPPY_FOUND, if false, do not try to link with snappy
#  SNAPPY_LIBRARIES, Library path and libs
#  SNAPPY_INCLUDE_DIR, where to find the ICU headers

if (NOT DEFINED SNAPPY_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_snappy_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_snappy_exploded ${CMAKE_BINARY_DIR}/tlm/deps/snappy.exploded)

    find_path(SNAPPY_INCLUDE_DIR snappy.h
              HINTS ${_snappy_exploded}/include
              ${_snappy_no_default_path})

    if (NOT SNAPPY_INCLUDE_DIR)
        message(FATAL_ERROR "Failed to locate snappy.h")
    endif ()

    find_library(SNAPPY_LIBRARIES
                 NAMES snappy
                 HINTS
                 ${_snappy_exploded}/lib
                 ${_snappy_no_default_path})

    if (NOT SNAPPY_LIBRARIES)
        message(FATAL_ERROR "Failed to locate snappy library")
    endif ()

    message(STATUS "Found snappy headers in: ${SNAPPY_INCLUDE_DIR}")
    message(STATUS "              libraries: ${SNAPPY_LIBRARIES}")
    set(SNAPPY_FOUND true CACHE BOOL "Found Google Snappy" FORCE)
    mark_as_advanced(SNAPPY_FOUND SNAPPY_INCLUDE_DIR SNAPPY_LIBRARIES)
endif (NOT DEFINED SNAPPY_FOUND)
