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
# This module defines all the variables defined by the standard FindBoost
# module (https://cmake.org/cmake/help/latest/module/FindBoost.html), plus
# the following variables for compability with our original custom logic to
# locate Boost:
#   BOOST_INCLUDE_DIR, where to find the boost headers (copy of
#                      Boost_INCLUDE_DIR - note the case).

if (NOT DEFINED Boost_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_is_supported_platform)
    if (_is_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(Boost_NO_SYSTEM_PATHS ON)
    endif ()

    set(Boost_ADDITIONAL_VERSIONS "1.67")
    set(Boost_DETAILED_FAILURE_MSG ON)
    set(Boost_USE_STATIC_LIBS ON)

    set(BOOST_ROOT ${CMAKE_BINARY_DIR}/tlm/deps/boost.exploded)

    find_package(Boost
            REQUIRED
            COMPONENTS system thread context)

    if(Boost_INCLUDE_DIR)
        message(STATUS "Found Boost in ${Boost_INCLUDE_DIR}")
        # Backwards compatabilty
        set(BOOST_INCLUDE_DIR ${Boost_INCLUDE_DIR} CACHE STRING
                "Boost include directory (copy of Boost_INCLUDE_DIR)")
    else()
        message(FATAL_ERROR "Boost headers not found")
    endif()
endif()
