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

# Locate lz4 library
# This module defines
#  LZ4_FOUND, if false, do not try to link with lz4
#  LZ4_LIBRARIES, Library path and libs
#  LZ4_INCLUDE_DIR, where to find the ICU headers

if (NOT DEFINED LZ4_FOUND)
    set(_lz4_exploded ${CMAKE_BINARY_DIR}/tlm/deps/lz4.exploded)
    set(_lz4_library_dir ${CMAKE_INSTALL_PREFIX})

    include(PlatformIntrospection)

    cb_get_supported_platform(_is_supported_platform)
    if (_is_supported_platform)
        # Supported platforms should only use the provided hints and pick up
        # LZ4 from cbdeps
        set(_lz4_no_default_path NO_DEFAULT_PATH)
    endif ()

    find_path(LZ4_INCLUDE_DIR lz4.h
              HINTS ${_lz4_exploded}/include
              ${_lz4_no_default_path})

    find_library(LZ4_LIBRARIES
                 NAMES lz4
                 HINTS ${_lz4_library_dir}/lib
                 ${_lz4_no_default_path})

    if (LZ4_INCLUDE_DIR AND LZ4_LIBRARIES)
        set(LZ4_FOUND True CACHE BOOL "Whether LZ4 has been found" FORCE)
        message(STATUS "Found LZ4 headers in: ${LZ4_INCLUDE_DIR}")
        message(STATUS "           libraries: ${LZ4_LIBRARIES}")
    else ()
        message(WARNING "LZ4 not found")
        set(LZ4_FOUND False CACHE BOOL "Whether LZ4 has been found" FORCE)
    endif ()

    mark_as_advanced(LZ4_FOUND LZ4_INCLUDE_DIR LZ4_LIBRARIES)
endif (NOT DEFINED LZ4_FOUND)
