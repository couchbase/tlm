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

# Locate Windows' DbgHelp.dll
if (NOT WIN32)
    # This file doesn't make sense to include on !Windows platforms
    return()
endif ()

# This module defines
#  DBGHELP_FOUND, set to true if found
#  DBGHELP_LIBRARY, Library path and libs
#  DBGHELP_DLL, Path to .dll file
if (NOT DEFINED DBGHELP_FOUND)
    include(PlatformIntrospection)

    find_library(DBGHELP_LIBRARY NAMES "DbgHelp")

    # Need the .dll file to copy into our install directory. Note we require
    # a matching architecture file.
    _determine_arch(HOST_ARCH)
    if (HOST_ARCH STREQUAL "amd64")
        set(_progfilesx86 "PROGRAMFILES(x86)")
        file(GLOB dbghelp_hint "$ENV{${_progfilesx86}}/Microsoft Visual Studio */Common7/IDE/Remote Debugger/x64")
    else (HOST_ARCH STREQUAL "amd64")
        file(GLOB dbghelp_hint "$ENV{PROGRAMFILES}/Microsoft Visual Studio */Common7/IDE/Remote Debugger/x86")
    endif (HOST_ARCH STREQUAL "amd64")
    message(STATUS "ENV{PROGRAMW6432} : $ENV{PROGRAMW6432}")
    message(STATUS "ENV{PROGRAMFILES} : $ENV{PROGRAMFILES}")
    message(STATUS "DbgHelp arch: ${HOST_ARCH} paths: ${dbghelp_hint}")
    find_file(DBGHELP_DLL dbghelp.dll NO_SYSTEM_ENVIRONMENT_PATH HINTS ${dbghelp_hint})

    if (DBGHELP_LIBRARY AND DBGHELP_DLL)
        message(STATUS "Found Dbghelp in ${DBGHELP_LIBRARY} : ${DBGHELP_DLL}")
    else (DBGHELP_LIBRARY AND DBGHELP_DLL)
        message(FATAL_ERROR "Can't build Couchbase without DbgHelp.dll")
    endif (DBGHELP_LIBRARY AND DBGHELP_DLL)

    set(DBGHELP_FOUND true CACHE BOOL "Found DbgHelp" FORCE)
    mark_as_advanced(DBGHELP_FOUND DBGHELP_LIBRARY DBGHELP_DLL)
endif (NOT DEFINED DBGHELP_FOUND)
