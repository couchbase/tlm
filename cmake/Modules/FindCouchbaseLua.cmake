# Locate lua library
# This module defines
#  LUA_FOUND, if false, do not try to link with lua
#  LUA_LIBRARIES, Library path and libs
#  LUA_INCLUDE_DIR, where to find the ICU headers

FIND_PATH(LUA_INCLUDE_DIR lua.h
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

FIND_LIBRARY(LUA_LIBRARIES
             NAMES lua lua5.2 lua5.1
             HINTS
                 ENV LUA_DIR
             PATHS
                 ~/Library/Frameworks
                 /Library/Frameworks
                 /opt/local
                 /opt/csw
                 /opt/lua
                 /opt)

IF (LUA_LIBRARIES)
  SET(LUA_FOUND true)
  MESSAGE(STATUS "Found lua in ${LUA_INCLUDE_DIR} : ${LUA_LIBRARIES}")
ELSE (LUA_LIBRARIES)
  SET(LUA_FOUND false)
ENDIF (LUA_LIBRARIES)

MARK_AS_ADVANCED(LUA_FOUND LUA_INCLUDE_DIR LUA_LIBRARIES)
