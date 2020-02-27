#
#     Copyright 2020 Couchbase, Inc.
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


# Try to locate libnuma and set NUMA_FOUND to true or false depending on
# the availability.
#
# If found:
#   A new compile flag is set: -D HAVE_LIBNUMA=1
#   CMake variables for include NUMA_INCLUDE_DIR and library NUMA_LIBRARIES
#   is set with the appropriate values
if (NOT DEFINED NUMA_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        # Supported platforms should only use the provided hints and pick it up
        # from cbdeps
        set(_numa_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_numa_exploded ${CMAKE_BINARY_DIR}/tlm/deps/numactl.exploded)

    find_path(NUMA_INCLUDE_DIR numa.h
              HINTS ${_numa_exploded}/include
              ${_numa_no_default_path})
    find_library(NUMA_LIBRARIES
                 NAMES numa
                 PATHS ${CMAKE_INSTALL_PREFIX}/lib/
                 ${_numa_no_default_path})

    if (NUMA_INCLUDE_DIR AND NUMA_LIBRARIES)
        cmake_push_check_state(RESET)
        set(CMAKE_REQUIRED_INCLUDES ${CMAKE_REQUIRED_INCLUDES} ${NUMA_INCLUDE_DIR})
        set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES} ${NUMA_LIBRARIES})
        check_c_source_compiles("
     #include <numa.h>
     int main() {
        numa_available();
     }" HAVE_LIBNUMA)
        cmake_pop_check_state()

        if (HAVE_LIBNUMA)
            add_definitions(-DHAVE_LIBNUMA=1)
            message(STATUS "Found numa headers in: ${NUMA_INCLUDE_DIR}")
            message(STATUS "              library: ${NUMA_LIBRARIES}")
            set(NUMA_FOUND true CACHE BOOL "Found numa" FORCE)
        else ()
            # we failed to build the program with numa
            set(NUMA_FOUND false CACHE BOOL "Found numa" FORCE)
        endif ()
    else ()
        # we don't have the header and library
        set(NUMA_FOUND false CACHE BOOL "Found numa" FORCE)
    endif ()

    if (_supported_platform AND NOT WIN32 AND NOT APPLE AND NOT NUMA_FOUND)
        # verify that we have libnuma available in our supported builds
        # (should pick it up from cbdeps)
        # If only cmake could have defined LINUX ;)
        message(FATAL_ERROR "Can't build Couchbase server without libnuma")
    endif()

    mark_as_advanced(NUMA_FOUND NUMA_INCLUDE_DIR NUMA_LIBRARIES)
endif()
