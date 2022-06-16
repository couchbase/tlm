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
# This module defines the same outputs as CMake's FindOpenSSL.cmake
#  (https://cmake.org/cmake/help/latest/module/FindOpenSSL.html), primarily:
#
# The import targets:
#
#  OpenSSL::SSL - The OpenSSL ssl library, if found.
#  OpenSSL::Crypto - The OpenSSL crypto library, if found.
#
# The variables:
#
#  OPENSSL_FOUND, Set when OpenSSL is detected
#  OPENSSL_LIBRARIES, All OpenSSL libraries and their dependancies.
#  OPENSSL_INCLUDE_DIR, where to find the OpenSSL headers

include(PlatformIntrospection)
cb_get_supported_platform(_is_supported_platform)
if (_is_supported_platform)
    # Supported platforms should only use the provided hints and pick it up
    # from cbdeps
    set(OPENSSL_ROOT_DIR ${CMAKE_BINARY_DIR}/tlm/deps/openssl.exploded)

    set(original_CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH ${CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH})
    set(original_CMAKE_FIND_USE_CMAKE_SYSTEM_PATH ${CMAKE_FIND_USE_CMAKE_SYSTEM_PATH})

    set(CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH FALSE)
    set(CMAKE_FIND_USE_CMAKE_SYSTEM_PATH FALSE)
endif ()

find_package(OpenSSL REQUIRED COMPONENTS Crypto SSL)

if (_is_supported_platform)
   set(CMAKE_FIND_USE_CMAKE_SYSTEM_PATH ${original_CMAKE_FIND_USE_CMAKE_SYSTEM_PATH})
   set(CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH ${original_CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH})
endif ()

