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
    # CBD-2634: We use ICU from V8 build as most uses of ICU is with V8
    if (NOT DEFINED V8_FOUND)
        include(FindCouchbaseV8)
    endif ()

    find_path(ICU_INCLUDE_DIR unicode/utypes.h
              HINTS ${V8_INCLUDE_DIR}
              NO_CMAKE_PATH
              NO_CMAKE_ENVIRONMENT_PATH
              NO_DEFAULT_PATH)

    if (NOT ICU_INCLUDE_DIR)
        message(FATAL_ERROR "Failed to locate unicode/utypes.h (ICU)")
    endif ()

    if (WIN32)
        if (CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
            set(_build_type "Release")
        else ()
            set(_build_type ${CMAKE_BUILD_TYPE})
        ENDIF()

        if (NOT ICU_LIBRARIES)
            set(_icu_libraries "icuuc.dll;icudata.dll;icui18n.dll;icucdt.dll;icuin.dll")
            foreach (_mylib ${_icu_libraries})
                unset(_the_lib CACHE)
                find_library(_the_lib
                            NAMES ${_mylib}
                            HINTS ${_v8_exploded}/lib/${_build_type}
                            NO_DEFAULT_PATH)
                if (_the_lib)
                    list(APPEND _icu_libs_found ${_the_lib})
                endif (_the_lib)
            endforeach (_mylib)
            set(ICU_LIBRARIES ${_icu_libs_found} CACHE STRING "V8 Libraries" FORCE)
        endif (NOT ICU_LIBRARIES)
    else (WIN32)
        if (NOT ICU_LIBRARIES)
            set(_icu_libraries "icuuc;icudata;icui18n;icucdt;icuin")
            foreach (_mylib ${_icu_libraries})
                unset(_the_lib CACHE)
                find_library(_the_lib
                            NAMES ${_mylib}
                            HINTS ${CMAKE_INSTALL_PREFIX}/lib
                            NO_DEFAULT_PATH)
                if (_the_lib)
                    list(APPEND _icu_libs_found ${_the_lib})
                endif (_the_lib)
            endforeach (_mylib)
            set(ICU_LIBRARIES ${_icu_libs_found} CACHE STRING "V8 Libraries" FORCE)
        endif (NOT ICU_LIBRARIES)
    endif (WIN32)

    if (NOT ICU_LIBRARIES)
        message(FATAL_ERROR "Failed to locate any of the ICU libraries")
    endif ()

    message(STATUS "Found ICU headers in: ${ICU_INCLUDE_DIR}")
    message(STATUS "           libraries: ${ICU_LIBRARIES}")

    set(ICU_FOUND true CACHE BOOL "Found ICU" FORCE)
    MARK_AS_ADVANCED(ICU_FOUND ICU_INCLUDE_DIR ICU_LIBRARIES)
endif (NOT DEFINED ICU_FOUND)
