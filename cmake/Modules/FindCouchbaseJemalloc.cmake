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
#  JEMALLOC_LIBRARIES, path to selected (Debug / Release) library variant
#  JEMALLOC_INCLUDE_DIR, where to find the jemalloc headers

IF (NOT FindCouchbaseJemalloc_INCLUDED)

INCLUDE(CheckFunctionExists)
include(CMakePushCheckState)
include(CheckSymbolExists)
include(FindPackageHandleStandardArgs)
include(PlatformIntrospection)
include(SelectLibraryConfigurations)

cb_get_supported_platform(_is_supported_platform)
if (_is_supported_platform)
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

# On Windows also need to add the 'msvc_compat' subdir to include path to
# provide an implementation of <strings.h>.
if (WIN32)
    list(APPEND JEMALLOC_INCLUDE_DIR ${JEMALLOC_INCLUDE_DIR}/msvc_compat)
endif ()

# find the Release library and Debug library (if it exists).
#
# We need to put _jemalloc_exploded/lib/* as hints as we don't
# install the .lib file to ${CMAKE_INSTALL_PREFIX} on Windows-
# they are left in the exploded directory.
find_library(JEMALLOC_LIBRARY_RELEASE
             NAMES jemalloc
             HINTS ${CMAKE_INSTALL_PREFIX}/lib
                   ${_jemalloc_exploded}/lib/Release
                   ${_jemalloc_exploded}/lib
             ${_jemalloc_no_default_path})

find_library(JEMALLOC_LIBRARY_DEBUG
             NAMES jemallocd
             HINTS ${CMAKE_INSTALL_PREFIX}/lib
                   ${_jemalloc_exploded}/lib/Debug
             ${_jemalloc_no_default_path})

# Set JEMALLOC_LIBRARIES to the correct Debug / Release lib based on the
# current BUILD_TYPE
select_library_configurations(JEMALLOC)

MESSAGE(STATUS "Found jemalloc headers: ${JEMALLOC_INCLUDE_DIR}")
MESSAGE(STATUS "             libraries: ${JEMALLOC_LIBRARIES}")

# Check that the found jemalloc library has it's symbols prefixed with 'je_'
cmake_push_check_state(RESET)
set(CMAKE_REQUIRED_LIBRARIES ${JEMALLOC_LIBRARIES})
set(CMAKE_REQUIRED_INCLUDES ${JEMALLOC_INCLUDE_DIR})
check_symbol_exists(je_malloc "stdbool.h;jemalloc/jemalloc.h" HAVE_JE_SYMBOLS)
check_symbol_exists(je_sdallocx "stdbool.h;jemalloc/jemalloc.h" HAVE_JEMALLOC_SDALLOCX)
cmake_pop_check_state()

if (NOT HAVE_JE_SYMBOLS)
    message(FATAL_ERROR "Found jemalloc in ${JEMALLOC_LIBRARIES}, but was built without 'je_' prefix on symbols so cannot be used.")
endif ()

mark_as_advanced(JEMALLOC_INCLUDE_DIR)

# Pretend we're using Modern CMake to find this thing.
add_library(Jemalloc::jemalloc STATIC IMPORTED)
set_target_properties(Jemalloc::jemalloc
    PROPERTIES
    IMPORTED_LOCATION ${JEMALLOC_LIBRARY_RELEASE})
if(FOLLY_LIBRARY_DEBUG)
    set_target_properties(Jemalloc::jemalloc
        PROPERTIES
        IMPORTED_LOCATION_DEBUG ${JEMALLOC_LIBRARY_DEBUG})
endif()
target_include_directories(Jemalloc::jemalloc INTERFACE
    ${JEMALLOC_INCLUDE_DIR})

SET (FindCouchbaseJemalloc_INCLUDED 1)
ENDIF (NOT FindCouchbaseJemalloc_INCLUDED)