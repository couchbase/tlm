# Locate Windows' DbgHelp.dll

# This module defines
#  DBGHELP_LIBRARY, Library path and libs
#  DBGHELP_DLL, Path to .dll file

INCLUDE(PlatformIntrospection)

FIND_LIBRARY(DBGHELP_LIBRARY NAMES "DbgHelp")

# Need the .dll file to copy into our install directory. Note we require
# a matching architecture file.
_DETERMINE_ARCH(HOST_ARCH)
IF(HOST_ARCH STREQUAL "amd64")
  SET (_progfilesx86 "PROGRAMFILES(x86)")
  FILE(GLOB dbghelp_hint "$ENV{${_progfilesx86}}/Microsoft Visual Studio */Common7/IDE/Remote Debugger/x64")
ELSE(HOST_ARCH STREQUAL "amd64")
  FILE(GLOB dbghelp_hint "$ENV{PROGRAMFILES}/Microsoft Visual Studio */Common7/IDE/Remote Debugger/x86")
ENDIF(HOST_ARCH STREQUAL "amd64")
MESSAGE(STATUS "ENV{PROGRAMW6432} : $ENV{PROGRAMW6432}")
MESSAGE(STATUS "ENV{PROGRAMFILES} : $ENV{PROGRAMFILES}")
MESSAGE(STATUS "DbgHelp arch: ${HOST_ARCH} paths: ${dbghelp_hint}")
FIND_FILE(DBGHELP_DLL dbghelp.dll NO_SYSTEM_ENVIRONMENT_PATH HINTS ${dbghelp_hint})

IF (DBGHELP_LIBRARY AND DBGHELP_DLL)
  MESSAGE(STATUS "Found Dbghelp in ${DBGHELP_LIBRARY} : ${DBGHELP_DLL}")
ELSE (DBGHELP_LIBRARY AND DBGHELP_DLL)
  MESSAGE(FATAL_ERROR "Can't build Couchbase without DbgHelp.dll")
ENDIF (DBGHELP_LIBRARY AND DBGHELP_DLL)

MARK_AS_ADVANCED(DBGHELP_LIBRARY DBGHELP_DLL)
