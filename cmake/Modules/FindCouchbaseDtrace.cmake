# stupid systemtap use a binary named dtrace as well, but it's not dtrace
IF (NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
   IF (CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
      MESSAGE(STATUS "We don't have support for DTrace on FreeBSD")
   ELSE (CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
      FIND_PROGRAM(DTRACE dtrace)
      IF (DTRACE)
         SET(ENABLE_DTRACE True CACHE BOOL "Whether DTrace has been found")
         MESSAGE(STATUS "Found dtrace in ${DTRACE}")

         IF (CMAKE_SYSTEM_NAME MATCHES "SunOS")
            SET(DTRACE_NEED_INSTRUMENT True CACHE BOOL
                "Whether DTrace should instrument object files")
         ENDIF (CMAKE_SYSTEM_NAME MATCHES "SunOS")
      ENDIF (DTRACE)

      MARK_AS_ADVANCED(DTRACE_NEED_INSTRUMENT ENABLE_DTRACE DTRACE)
   ENDIF (CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
ENDIF (NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
