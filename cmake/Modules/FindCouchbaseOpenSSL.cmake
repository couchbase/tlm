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

# Locate OpenSSL library
#
# For Windows and MacOSX we bundle our own version, but for the
# other platforms we should search for a system-wide installed
# version.
#
# This module defines
#  OPENSSL_FOUND, Set when OpenSSL is detected
#  OPENSSL_LIBRARIES, Library path and libs
#  OPENSSL_INCLUDE_DIR, where to find the OpenSSL headers

if (NOT DEFINED OPENSSL_FOUND)
    include(PlatformIntrospection)
    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_openssl_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_openssl_exploded ${CMAKE_BINARY_DIR}/tlm/deps/openssl.exploded)
    set(_openssl_libraries "ssl;libssl32;ssleay32;crypto;libeay32")

    find_path(OPENSSL_INCLUDE_DIR openssl/ssl.h
              HINTS ${_openssl_exploded}
              PATH_SUFFIXES include
              NO_CMAKE_PATH
              NO_CMAKE_ENVIRONMENT_PATH
              ${_openssl_no_default_path})

    string(STRIP ${OPENSSL_INCLUDE_DIR} OPENSSL_INCLUDE_DIR)
    if (NOT OPENSSL_LIBRARIES)
        foreach (_mylib ${_openssl_libraries})
            unset(_the_lib CACHE)
            find_library(_the_lib
                         NAMES ${_mylib}
                         HINTS ${CMAKE_INSTALL_PREFIX}/lib
                         ${_openssl_no_default_path})
            if (_the_lib)
                list(APPEND _openssl_libs_found ${_the_lib})
            endif (_the_lib)
        endforeach (_mylib)
        set(OPENSSL_LIBRARIES ${_openssl_libs_found} CACHE STRING "OpenSSL Libraries" FORCE)
    endif (NOT OPENSSL_LIBRARIES)

    if (OPENSSL_LIBRARIES AND OPENSSL_INCLUDE_DIR)
        message(STATUS "Found OpenSSL headers in: ${OPENSSL_INCLUDE_DIR}")
        message(STATUS "               libraries: ${OPENSSL_LIBRARIES}")
    else (OPENSSL_LIBRARIES AND OPENSSL_INCLUDE_DIR)
        message(FATAL_ERROR "Can't build Couchbase without openssl")
    endif (OPENSSL_LIBRARIES AND OPENSSL_INCLUDE_DIR)

    set(OPENSSL_FOUND true CACHE BOOL "Found OpenSSL" FORCE)
    mark_as_advanced(OPENSSL_FOUND OPENSSL_INCLUDE_DIR OPENSSL_LIBRARIES)
endif (NOT DEFINED OPENSSL_FOUND)
