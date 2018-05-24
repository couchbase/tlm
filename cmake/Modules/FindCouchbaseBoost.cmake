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

# Locate Boost headers.
# This module defines
#  BOOST_FOUND, if boost was found
#  BOOST_INCLUDE_DIR, where to find the boost headers

if (NOT DEFINED BOOST_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_boost_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(boost_exploded ${CMAKE_BINARY_DIR}/tlm/deps/boost.exploded)

    find_path(BOOST_INCLUDE_DIR boost/intrusive/list.hpp
              HINTS ${boost_exploded}/include
              ${_boost_no_default_path})

    if (BOOST_INCLUDE_DIR)
        message(STATUS "Found boost in ${BOOST_INCLUDE_DIR}")
    else (BOOST_INCLUDE_DIR)
        message(FATAL_ERROR "Boost headers not found")
    endif (BOOST_INCLUDE_DIR)
    set(BOOST_FOUND true CACHE BOOL "Found boost" FORCE)
    mark_as_advanced(BOOST_FOUND BOOST_INCLUDE_DIR)
endif (NOT DEFINED BOOST_FOUND)
