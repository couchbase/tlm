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

# Locate nlohmann JSON library

if (NOT DEFINED NLOHMANN_JSON_FOUND)
    include(PlatformIntrospection)
    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        find_package(nlohmann_json REQUIRED
                     PATHS ${CMAKE_BINARY_DIR}/tlm/deps/json.exploded
                     NO_DEFAULT_PATH)
    else ()
        find_package(nlohmann_json REQUIRED)
    endif ()

    # In a transition period until we have all consumers migrated over
    # to the new way to locate the library we should keep the old variables
    # around
    set(_nhlomann_json_exploded ${CMAKE_BINARY_DIR}/tlm/deps/json.exploded)
    if (EXISTS ${_nhlomann_json_exploded} AND IS_DIRECTORY ${_nhlomann_json_exploded})
        set(_nhlomann_json_no_default_path NO_DEFAULT_PATH)
    endif ()
    find_path(NLOHMANN_JSON_INCLUDE_DIR nlohmann/json.hpp
              HINTS ${_nhlomann_json_exploded}/include
              ${_nhlomann_json_no_default_path})

    if (NOT NLOHMANN_JSON_INCLUDE_DIR)
        message(FATAL_ERROR "Failed to locate nlohmann/json.hpp")
    endif (NOT NLOHMANN_JSON_INCLUDE_DIR)

    message(STATUS "Found nlohmann json in: ${NLOHMANN_JSON_INCLUDE_DIR}")
    set(NLOHMANN_JSON_FOUND true CACHE BOOL "Found nlohmann json" FORCE)
    mark_as_advanced(NLOHMANN_JSON_FOUND NLOHMANN_JSON_INCLUDE_DIR)
endif (NOT DEFINED NLOHMANN_JSON_FOUND)
