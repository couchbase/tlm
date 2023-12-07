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

# Locate cURL library
# This module defines
#  CURL_FOUND, if false, do not try to link with cURL
#  CURL_LIBRARIES, Library path and libs
#  CURL_INCLUDE_DIR, where to find the cURL headers
#
if (NOT DEFINED FindCouchbaseCurl_INCLUDED)
    include(PlatformIntrospection)
    # Use include files directly from cbdeps exploded download
    set(_curl_exploded "${CMAKE_BINARY_DIR}/tlm/deps/curl.exploded")

    cb_get_supported_platform(_is_supported_platform)
    if (_is_supported_platform)
        if (EXISTS ${_curl_exploded} AND IS_DIRECTORY ${_curl_exploded})
            # Supported platforms should only use the provided hints and
            # pick it up from cbdeps (but we don't bundle this for all
            # platforms)
            set(_curl_no_default_path NO_DEFAULT_PATH)
        endif ()
    endif ()

    find_path(CURL_INCLUDE_DIR curl/curl.h
              HINTS ${_curl_exploded}/include
              ${_curl_no_default_path})

    if (NOT CURL_INCLUDE_DIR)
        message(FATAL_ERROR "Failed to locate curl/curl.h")
    endif ()

    find_library(CURL_LIBRARIES
                 NAMES curl libcurl libcurl_imp
                 HINTS ${CMAKE_INSTALL_PREFIX}/lib
                 ${_curl_no_default_path})

    if (NOT CURL_LIBRARIES)
        message(FATAL_ERROR "Failed to locate curl, libcurl or libcurl_imp")
    endif ()

    message(STATUS "Found cURL headers in: ${CURL_INCLUDE_DIR}")
    message(STATUS "            libraries: ${CURL_LIBRARIES}")
    set(CURL_FOUND true CACHE BOOL "Found cURL" FORCE)
    mark_as_advanced(CURL_FOUND CURL_INCLUDE_DIR CURL_LIBRARIES)

    # Pretend we're using Modern CMake to find this thing.
    add_library(Curl::libcurl SHARED IMPORTED)
    set_target_properties(Curl::libcurl
        PROPERTIES
        IMPORTED_LOCATION ${CURL_LIBRARIES})
    target_include_directories(Curl::libcurl INTERFACE
        ${CURL_INCLUDE_DIR})

    set(FindCouchbaseCurl_INCLUDED 1)

endif (NOT DEFINED FindCouchbaseCurl_INCLUDED)
