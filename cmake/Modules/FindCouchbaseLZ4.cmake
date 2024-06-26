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

# We want to only find our cbdeps package
SET (lz4_ROOT "${CMAKE_BINARY_DIR}/tlm/deps/lz4.exploded")
FIND_PACKAGE (lz4 CONFIG
    NO_CMAKE_PATH NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_INSTALL_PREFIX)
if (TARGET LZ4::lz4_shared)
    set(LZ4_FOUND True CACHE BOOL "Whether LZ4 has been found" FORCE)
    get_target_property(_lz4_location LZ4::lz4_shared LOCATION)
    # Annoyingly, the exported targets for LZ4 don't have INCLUDE_DIRECTORIES
    # even though it looks like they should, so force it in
    set_target_properties(LZ4::lz4_shared PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${lz4_ROOT}/include")
    message(STATUS "Found LZ4: ${_lz4_location}")
    message(STATUS "         : ${lz4_ROOT}/include")
else ()
    message(WARNING "LZ4 not found")
    set(LZ4_FOUND False CACHE BOOL "Whether LZ4 has been found" FORCE)
endif ()
