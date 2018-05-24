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

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    # stupid systemtap use a binary named dtrace as well, but it's not dtrace
    return()
endif ()

# This module defines the following values
#    DTRACE_FOUND - set to true if we have dtrace
#    DTRACE_EXECUTABLE - the name of the DTrace executable
#    DTRACE - for backwards compatibility (deprecated, use dtrace executable instead)
#    DTRACE_NEED_INSTRUMENT - set to true if dtrace must instrument the object files
if (NOT DEFINED DTRACE_FOUND)
    find_program(DTRACE_EXECUTABLE dtrace)
    if (DTRACE_EXECUTABLE)
        set(ENABLE_DTRACE True CACHE BOOL "Whether DTrace has been found")
        message(STATUS "Found dtrace in ${DTRACE_EXECUTABLE}")

        if (CMAKE_SYSTEM_NAME MATCHES "SunOS|FreeBSD")
            set(DTRACE_NEED_INSTRUMENT True CACHE BOOL
                "Whether DTrace should instrument object files" FORCE)
        endif (CMAKE_SYSTEM_NAME MATCHES "SunOS|FreeBSD")
        set(DTRACE_FOUND true CACHE BOOL "Found DTrace" FORCE)
        set(DTRACE ${DTRACE_EXECUTABLE} CACHE FILEPATH "Path to dtrace binary" FORCE)
    else (DTRACE_EXECUTABLE)
        set(DTRACE_FOUND false CACHE BOOL "DTrace not available" FORCE)
    endif (DTRACE_EXECUTABLE)

    mark_as_advanced(DTRACE_FOUND DTRACE_NEED_INSTRUMENT ENABLE_DTRACE DTRACE_EXECUTABLE DTRACE)
endif (NOT DEFINED DTRACE_FOUND)

