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

# Locate breakpad library
# This module defines
#  BREAKPAD_FOUND, if false, do not try to link with breakpad
#  BREAKPAD_LIBRARIES, Library path and libs
#  BREAKPAD_INCLUDE_DIR, where to find the breakpad headers
#  MINIDUMP2CORE, program to generate a corefile from the minidump (UNIX only)

if (NOT DEFINED BREAKPAD_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_is_supported_platform)
    if (_is_supported_platform AND NOT APPLE)
        string(TOLOWER ${CMAKE_SYSTEM_NAME} LCASE_SYSTEM)

        set(_breakpad_exploded ${CMAKE_BINARY_DIR}/tlm/deps/breakpad.exploded)

        find_path(BREAKPAD_INCLUDE_DIR client/${LCASE_SYSTEM}/handler/exception_handler.h
                  HINTS ${_breakpad_exploded}/include
                  PATH_SUFFIXES breakpad)

        if (WIN32)
            # RelWithDebInfo & MinSizeRel should use the Release libraries, otherwise use
            # the same directory as the build type.
            if (CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
                set(_build_type "Release")
            else (CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
                set(_build_type ${CMAKE_BUILD_TYPE})
            endif (CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")

            find_library(BREAKPAD_EXCEPTION_HANDLER_LIBRARY
                         NAMES exception_handler
                         PATHS ${_breakpad_exploded}/lib/${_build_type})

            find_library(BREAKPAD_CRASH_GENERATION_LIBRARY
                         NAMES crash_generation_client
                         PATHS ${_breakpad_exploded}/lib/${_build_type})

            find_library(BREAKPAD_COMMON_LIBRARY
                         NAMES common
                         PATHS ${_breakpad_exploded}/lib/${_build_type})

            set(BREAKPAD_LIBRARIES
                ${BREAKPAD_EXCEPTION_HANDLER_LIBRARY}
                ${BREAKPAD_CRASH_GENERATION_LIBRARY}
                ${BREAKPAD_COMMON_LIBRARY}
                CACHE FILEPATH "Breakpad library path")

            # not used, just set to simplify the test below
            set(MINIDUMP2CORE true)
        else (WIN32)
            find_library(BREAKPAD_LIBRARIES
                         NAMES breakpad_client
                         HINTS ${_breakpad_exploded}/lib)

            find_program(MINIDUMP2CORE minidump-2-core HINTS ${CMAKE_INSTALL_PREFIX}/bin)
            if (MINIDUMP2CORE)
                message(STATUS "Found minidump-2-core: ${MINIDUMP2CORE}")
            endif (MINIDUMP2CORE)
        endif (WIN32)

        if (BREAKPAD_LIBRARIES AND BREAKPAD_INCLUDE_DIR AND MINIDUMP2CORE)
            set(BREAKPAD_FOUND True CACHE BOOL "Whether Google Breakpad has been found" FORCE)
            message(STATUS "Found Google Breakpad:")
            message(STATUS "   headers: ${BREAKPAD_INCLUDE_DIR}")
            message(STATUS "   library: ${BREAKPAD_LIBRARIES}")
        else (BREAKPAD_LIBRARIES AND BREAKPAD_INCLUDE_DIR AND MINIDUMP2CORE)
            message(FATAL_ERROR "Google Breakpad not found (required on supported production platforms).")
        endif (BREAKPAD_LIBRARIES AND BREAKPAD_INCLUDE_DIR AND MINIDUMP2CORE)

        mark_as_advanced(BREAKPAD_FOUND BREAKPAD_LIBRARIES BREAKPAD_INCLUDE_DIR MINIDUMP2CORE)
    else ()
        # Unsupported platforms
        message(STATUS "Google Breakpad is only used on supported platforms")
        set(BREAKPAD_FOUND False CACHE BOOL "Whether Google Breakpad has been found" FORCE)
        mark_as_advanced(BREAKPAD_FOUND)
    endif ()
endif (NOT DEFINED BREAKPAD_FOUND)
