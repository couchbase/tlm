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

# Locate Google flatbuffers
# This module defines
#  FLATBUFFERS_INCLUDE_DIR, where to find the flatbuffer headers
#  FLATC, the flatc binary
include(PlatformIntrospection)

cb_get_supported_platform(_is_supported_platform)
if (_is_supported_platform)
    # Supported platforms should only use the provided hints and pick it up
    # from cbdeps
    set(_flatbuffers_no_default_path NO_DEFAULT_PATH)
endif ()

set(google_flatbuffers_exploded ${CMAKE_BINARY_DIR}/tlm/deps/flatbuffers.exploded)

find_path(FLATBUFFERS_INCLUDE_DIR flatbuffers/flatbuffers.h
            HINTS ${google_flatbuffers_exploded}/include
            ${_flatbuffers_no_default_path})
if (NOT FLATBUFFERS_INCLUDE_DIR)
    message(FATAL_ERROR "Failed to locate flatbuffers/flatbuffers.h")
endif ()

find_program(FLATC flatc HINTS ${google_flatbuffers_exploded}/bin ${_flatbuffers_no_default_path})
if (NOT FLATC)
    message(FATAL_ERROR "Failed to locate flatc")
endif ()

find_library(FLATBUFFERS_LIBRARY_RELEASE
             NAMES flatbuffers
             PATHS ${google_flatbuffers_exploded}/lib/)

find_library(FLATBUFFERS_LIBRARY_DEBUG
             NAMES flatbuffersd
             PATHS ${google_flatbuffers_exploded}/lib/)

# Defines FLATBUFFERS_LIBRARY / LIBRARIES to the correct Debug / Release
# lib based on the current BUILD_TYPE
select_library_configurations(FLATBUFFERS)

if (NOT FLATBUFFERS_LIBRARIES)
    message(FATAL_ERROR "Failed to locate flatbuffers library")
endif ()

message(STATUS "Found Google Flatbuffers headers in: ${FLATBUFFERS_INCLUDE_DIR}")
message(STATUS "                            library: ${FLATBUFFERS_LIBRARIES}")
message(STATUS "                           compiler: ${FLATC}")

mark_as_advanced(FLATBUFFERS_INCLUDE_DIR FLATC FLATBUFFERS_LIBRARIES)
