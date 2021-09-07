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

# We build a separate TSan library for RocksDB as we otherwise end up with some
# odd issues if the linker picks up unannotated symbols.
if (CB_THREADSANITIZER)
    set(rocksdb_lib rocksdbtsan)
else(CB_THREADSANITIZER)
    set(rocksdb_lib rocksdb)
endif(CB_THREADSANITIZER)

# Locate RocksDB library
# This module defines
#  ROCKSDB_FOUND, if false, do not try to link with rocksdb
#  ROCKSDB_LIBRARIES, Library path and libs
#  ROCKSDB_INCLUDE_DIR, where to find the rocksdb headers
if (NOT DEFINED ROCKSDB_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_is_supported_platform)
    if (_is_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_rocksdb_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_rocksdb_exploded ${CMAKE_BINARY_DIR}/tlm/deps/rocksdb.exploded)

    find_path(ROCKSDB_INCLUDE_DIR rocksdb/db.h
              PATH_SUFFIXES include
              PATHS ${_rocksdb_exploded}
              ${_rocksdb_no_default_path})

    find_library(ROCKSDB_LIBRARIES
                 NAMES ${rocksdb_lib}
                 HINTS ${CMAKE_INSTALL_PREFIX}/lib
                 ${_rocksdb_no_default_path})

    if (ROCKSDB_INCLUDE_DIR AND ROCKSDB_LIBRARIES)
        message(STATUS "Found RocksDB headers in: ${ROCKSDB_INCLUDE_DIR}")
        message(STATUS "               libraries: ${ROCKSDB_LIBRARIES}")
        set(ROCKSDB_FOUND true CACHE BOOL "Found RocksDB" FORCE)
    else ()
        message(STATUS "RocksDB not found")
        set(ROCKSDB_FOUND false CACHE BOOL "RocksDB not found" FORCE)
    endif ()

    mark_as_advanced(ROCKSDB_FOUND ROCKSDB_INCLUDE_DIR ROCKSDB_LIBRARIES)
endif (NOT DEFINED ROCKSDB_FOUND)
