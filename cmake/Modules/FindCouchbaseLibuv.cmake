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

# Locate libuv library
# This module defines
#  LIBUV_FOUND, if libuv was found
#  LIBUV_LIBRARIES, Library path and libs
#  LIBUV_INCLUDE_DIR, where to find the libuv headers
if (NOT DEFINED LIBUV_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_is_supported_platform)
    if (_is_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_libuv_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_libuv_exploded ${CMAKE_BINARY_DIR}/tlm/deps/libuv.exploded)
    find_path(LIBUV_INCLUDE_DIR uv.h
              HINTS ${_libuv_exploded}/include
              ${_libuv_no_default_path})

    if (NOT LIBUV_INCLUDE_DIR)
        message(FATAL_ERROR "Failed to locate uv.h")
    endif ()

    find_library(LIBUV_LIBRARIES
                 NAMES uv libuv
                 HINTS ${CMAKE_INSTALL_PREFIX}/lib
                 ${_libuv_no_default_path})
    if (NOT LIBUV_LIBRARIES)
        message(FATAL_ERROR "Failed to locate libuv")
    endif ()

    message(STATUS "Found libuv headers in: ${LIBUV_INCLUDE_DIR}")
    message(STATUS "             libraries: ${LIBUV_LIBRARIES}")

    set(LIBUV_FOUND true CACHE BOOL "Found libuv" FORCE)
    mark_as_advanced(LIBUV_FOUND LIBUV_INCLUDE_DIR LIBUV_LIBRARIES)
endif (NOT DEFINED LIBUV_FOUND)
