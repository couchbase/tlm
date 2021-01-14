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

# Locate v8 library
# This module defines
#  V8_FOUND, if V8 was found
#  V8_LIBRARIES, Library path and libs
#  V8_INCLUDE_DIR, where to find V8 headers
if (NOT DEFINED V8_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_v8_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_v8_exploded ${CMAKE_BINARY_DIR}/tlm/deps/v8.exploded)

    find_path(V8_INCLUDE_DIR v8.h
              HINTS ${_v8_exploded}/include
              ${_v8_no_default_path})

    if (NOT V8_INCLUDE_DIR)
        message(FATAL_ERROR "Failed to locate v8.h")
    endif ()

    if (WIN32)
        # RelWithDebInfo & MinSizeRel should use the Release libraries, otherwise use
        # the same directory as the build type.
        if (CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo" OR CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
            set(_build_type "Release")
        else ()
            set(_build_type ${CMAKE_BUILD_TYPE})
        ENDIF ()

        if (NOT V8_LIBRARIES)
            set(_v8_libraries "v8.dll;v8_libplatform.dll;v8_libbase.dll;zlib.dll")
            foreach (_mylib ${_v8_libraries})
                unset(_the_lib CACHE)
                find_library(_the_lib
                             NAMES ${_mylib}
                             HINTS ${_v8_exploded}/lib/${_build_type}
                             ${_v8_no_default_path})
                if (_the_lib)
                    list(APPEND _v8_libs_found ${_the_lib})
                endif (_the_lib)
            endforeach (_mylib)
            set(V8_LIBRARIES ${_v8_libs_found} CACHE STRING "V8 Libraries" FORCE)
        endif (NOT V8_LIBRARIES)
    else (WIN32)
        if (NOT V8_LIBRARIES)
            set(_v8_libraries "v8;v8_libplatform;v8_libbase;libchrome_zlib")
            foreach (_mylib ${_v8_libraries})
                unset(_the_lib CACHE)
                find_library(_the_lib
                             NAMES ${_mylib}
                             HINTS ${CMAKE_INSTALL_PREFIX}/lib
                             ${_v8_no_default_path})
                if (_the_lib)
                    list(APPEND _v8_libs_found ${_the_lib})
                endif (_the_lib)
            endforeach (_mylib)
            set(V8_LIBRARIES ${_v8_libs_found} CACHE STRING "V8 Libraries" FORCE)
        endif (NOT V8_LIBRARIES)
    endif (WIN32)

    if (V8_LIBRARIES)
        message(STATUS "Found v8 headers in: ${V8_INCLUDE_DIR}")
        message(STATUS "          libraries: ${V8_LIBRARIES}")
    else (V8_LIBRARIES)
        message(FATAL_ERROR "Can't build Couchbase without V8")
    endif (V8_LIBRARIES)

    set(V8_FOUND true CACHE BOOL "Found V8" FORCE)
    mark_as_advanced(V8_FOUND V8_INCLUDE_DIR V8_LIBRARIES)
endif (NOT DEFINED V8_FOUND)
