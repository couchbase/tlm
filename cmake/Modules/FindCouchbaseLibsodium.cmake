#
#     Copyright 2022 Couchbase, Inc.
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

# Locate libsodium library
# This module defines
#  LIBSODIUM_FOUND, if libsodium was found
#  LIBSODIUM_LIBRARIES, Library path and libs
#  LIBSODIUM_INCLUDE_DIR, where to find the libsodium headers
if (NOT DEFINED LIBSODIUM_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_is_supported_platform)
    if (_is_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_libsodium_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_libsodium_exploded ${CMAKE_BINARY_DIR}/tlm/deps/libsodium.exploded)
    find_path(LIBSODIUM_INCLUDE_DIR sodium.h
              HINTS ${_libsodium_exploded}/include
              ${_libsodium_no_default_path})

    if (NOT LIBSODIUM_INCLUDE_DIR)
        message(FATAL_ERROR "Failed to locate sodium.h")
    endif ()

    find_library(LIBSODIUM_LIBRARIES
                 NAMES sodium libsodium
                 HINTS ${CMAKE_INSTALL_PREFIX}/lib
                 ${_libsodium_no_default_path})
    if (NOT LIBSODIUM_LIBRARIES)
        message(FATAL_ERROR "Failed to locate libsodium")
    endif ()

    message(STATUS "Found libsodium headers in: ${LIBSODIUM_INCLUDE_DIR}")
    message(STATUS "             libraries: ${LIBSODIUM_LIBRARIES}")

    set(LIBSODIUM_FOUND true CACHE BOOL "Found libsodium" FORCE)
    mark_as_advanced(LIBSODIUM_FOUND LIBSODIUM_INCLUDE_DIR LIBSODIUM_LIBRARIES)

    add_library(libsodium::libsodium STATIC IMPORTED)
    set_target_properties(libsodium::libsodium
            PROPERTIES
            IMPORTED_LOCATION ${LIBSODIUM_LIBRARIES})
    target_include_directories(libsodium::libsodium
            INTERFACE ${LIBSODIUM_INCLUDE_DIR})

endif (NOT DEFINED LIBSODIUM_FOUND)
