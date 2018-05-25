#
#     Copyright 2019 Couchbase, Inc.
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

# Locate lua library
# This module defines
#  LUA_FOUND, if false, do not try to link with lua
#  LUA_LIBRARIES, Library path and libs
#  LUA_INCLUDE_DIR, where to find the ICU headers

if (NOT DEFINED LUA_FOUND)
    find_path(LUA_INCLUDE_DIR lua.h
              HINTS
              ENV LUA_DIR
              PATH_SUFFIXES lua5.2
              lua-5.2
              lua5.1
              lua-5.1
              PATHS
              ~/Library/Frameworks
              /Library/Frameworks
              /opt/local
              /opt/csw
              /opt/lua
              /opt)

    find_library(LUA_LIBRARIES
                 NAMES lua5.2 lua5.1 lua
                 HINTS
                 ENV LUA_DIR
                 PATHS
                 ~/Library/Frameworks
                 /Library/Frameworks
                 /opt/local
                 /opt/csw
                 /opt/lua
                 /opt)

    if (LUA_LIBRARIES)
        set(LUA_FOUND true CACHE BOOL "Found LUA" FORCE)
        message(STATUS "Found lua headers in: ${LUA_INCLUDE_DIR}")
        message(STATUS "           libraries: ${LUA_LIBRARIES}")
    else (LUA_LIBRARIES)
        set(LUA_FOUND false CACHE BOOL "LUA not available" FORCE)
    endif (LUA_LIBRARIES)

    mark_as_advanced(LUA_FOUND LUA_INCLUDE_DIR LUA_LIBRARIES)
endif (NOT DEFINED LUA_FOUND)
