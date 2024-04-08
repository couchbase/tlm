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
#  JEMALLOC_NOPREFIX_LIBRARIES, path to select (Debug / Release) library
#     without je_ symbol prefix
#  JEMALLOC_INCLUDE_DIR, where to find the jemalloc headers (may be a list!)
#  JEMALLOC_NOPREFIX_INCLUDE_DIR, where to find the jemalloc headers (may be a list!)
#
# It also defines well-formed "Modern CMake" imported targets
# Jemalloc::jemalloc and Jemalloc::noprefix.

IF (NOT FindCouchbaseJemalloc_INCLUDED)

INCLUDE(CheckFunctionExists)
include(CMakePushCheckState)
include(CheckSymbolExists)

set(Jemalloc_ROOT ${CMAKE_BINARY_DIR}/tlm/deps/jemalloc.exploded)
find_package(Jemalloc REQUIRED)

# "Translate" variables to the old-school all-upper-case form we use.
set(JEMALLOC_FOUND 1)
set(JEMALLOC_INCLUDE_DIR ${Jemalloc_INCLUDE_DIRS})
set(JEMALLOC_NOPREFIX_INCLUDE_DIR ${Jemalloc_NOPREFIX_INCLUDE_DIRS})
set(JEMALLOC_LIBRARIES ${Jemalloc_LIBRARIES})
set(JEMALLOC_NOPREFIX_LIBRARIES ${Jemalloc_NOPREFIX_LIBRARIES})

# plasma and nitro also use this - they probably shouldn't
set(JEMALLOC_LIBRARY_RELEASE ${Jemalloc_LIBRARY_RELEASE})

mark_as_advanced(JEMALLOC_INCLUDE_DIR)

MESSAGE(STATUS "Found jemalloc headers: ${JEMALLOC_INCLUDE_DIR}")
MESSAGE(STATUS "             libraries: ${JEMALLOC_LIBRARIES}")
MESSAGE(STATUS "    noprefix libraries: ${JEMALLOC_NOPREFIX_LIBRARIES}")

# Check that the found jemalloc library has it's symbols prefixed with 'je_'
cmake_push_check_state(RESET)
set(CMAKE_REQUIRED_LIBRARIES ${JEMALLOC_LIBRARIES})
set(CMAKE_REQUIRED_INCLUDES ${JEMALLOC_INCLUDE_DIR})
check_symbol_exists(je_malloc "stdbool.h;jemalloc/jemalloc.h" HAVE_JE_SYMBOLS)
check_symbol_exists(je_sdallocx "stdbool.h;jemalloc/jemalloc.h" HAVE_JEMALLOC_SDALLOCX)
cmake_pop_check_state()

if (NOT HAVE_JE_SYMBOLS)
    message(FATAL_ERROR "Found jemalloc in ${JEMALLOC_INCLUDE_DIR}, but was built without 'je_' prefix on symbols so cannot be used.")
endif ()

SET (FindCouchbaseJemalloc_INCLUDED 1)
ENDIF (NOT FindCouchbaseJemalloc_INCLUDED)