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

# Locate icu4c library
# This module defines
#  ICU_FOUND, if false, do not try to link with ICU
#  ICU_LIBRARIES, Library path and libs
#  ICU_INCLUDE_DIR, where to find the ICU headers

if (NOT DEFINED ICU_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_icu_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_icu_exploded ${CMAKE_BINARY_DIR}/tlm/deps/icu4c.exploded)

    find_path(ICU_INCLUDE_DIR unicode/utypes.h
              HINTS ${_icu_exploded}
              PATH_SUFFIXES include
              NO_CMAKE_PATH
              NO_CMAKE_ENVIRONMENT_PATH
              ${_icu_no_default_path})

    if (NOT ICU_INCLUDE_DIR)
        message(FATAL_ERROR "Failed to locate unicode/utypes.h (ICU)")
    endif ()

    string(STRIP ${ICU_INCLUDE_DIR} ICU_INCLUDE_DIR)
    string(STRIP "${ICU_LIB_HINT_DIR}" ICU_LIB_HINT_DIR)

    if (NOT ICU_LIBRARIES)
        set(_icu_libraries "icuuc;icudata;icui18n;icucdt;icuin")
        foreach (_mylib ${_icu_libraries})
            unset(_the_lib CACHE)
            find_library(_the_lib
                         NAMES ${_mylib}
                         HINTS
                         ${ICU_LIB_HINT_DIR}
                         ${CMAKE_INSTALL_PREFIX}/lib
                         ${_icu_no_default_path})
            if (_the_lib)
                list(APPEND _icu_libs_found ${_the_lib})
            endif (_the_lib)
        endforeach (_mylib)
        set(ICU_LIBRARIES ${_icu_libs_found} CACHE STRING "V8 Libraries" FORCE)
    endif ()

    if (NOT ICU_LIBRARIES)
        message(FATAL_ERROR "Failed to locate any of the ICU libraries")
    endif ()

    message(STATUS "Found ICU headers in: ${ICU_INCLUDE_DIR}")
    message(STATUS "           libraries: ${ICU_LIBRARIES}")

    set(ICU_FOUND true CACHE BOOL "Found ICU" FORCE)
    MARK_AS_ADVANCED(ICU_FOUND ICU_INCLUDE_DIR ICU_LIBRARIES)
endif (NOT DEFINED ICU_FOUND)
