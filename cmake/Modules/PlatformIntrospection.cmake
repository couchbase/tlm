#
# Collection of common macros and code for introspecting the platform.

# Returns a simple string describing the current architecture. Possible
# return values currently include: amd64, x86_64, x86.
MACRO (_DETERMINE_ARCH var)
  IF (DEFINED CB_DOWNLOAD_DEPS_ARCH)
    SET (_arch ${CB_DOWNLOAD_DEPS_ARCH})
  ELSE (DEFINED CB_DOWNLOAD_DEPS_ARCH)
    # We tweak MacOS, which for some reason claims to be i386
    IF (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
      # QQQ MacOS 10.7 could be 32-bit; we should catch and abort
      SET (_arch x86_64)
    ELSEIF (CMAKE_SYSTEM_NAME STREQUAL "SunOS")
      EXECUTE_PROCESS (COMMAND isainfo -k
        COMMAND tr -d '\n'
        OUTPUT_VARIABLE _arch)
    ELSEIF (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
      IF (DEFINED ENV{PROCESSOR_ARCHITEW6432})
        STRING (TOLOWER "$ENV{PROCESSOR_ARCHITEW6432}" HOST_ARCH)
      ELSE ()
        STRING (TOLOWER "$ENV{PROCESSOR_ARCHITECTURE}" HOST_ARCH)
      ENDIF ()
    ELSE (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
      STRING (TOLOWER ${CMAKE_SYSTEM_PROCESSOR} _arch)
    ENDIF (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    MESSAGE (STATUS "Set arch to ${_arch} for dependency downloads")
    SET (CB_DOWNLOAD_DEPS_ARCH ${_arch} CACHE STRING
      "Architecture for downloaded dependencies")
    MARK_AS_ADVANCED (CB_DOWNLOAD_DEPS_ARCH)
  ENDIF (DEFINED CB_DOWNLOAD_DEPS_ARCH)
  SET (${var} ${_arch})
ENDMACRO (_DETERMINE_ARCH)


# Returns a lowercased version of a given lsb_release field.
MACRO (_LSB_RELEASE field retval)
  EXECUTE_PROCESS (COMMAND lsb_release "--${field}"
  OUTPUT_VARIABLE _output ERROR_VARIABLE _output RESULT_VARIABLE _result)
  IF (_result)
    MESSAGE (FATAL_ERROR "Cannot determine Linux revision! Output from "
    "lsb_release --${field}: ${_output}")
  ENDIF (_result)
  STRING (REGEX REPLACE "^[^:]*:" "" _output "${_output}")
  STRING (TOLOWER "${_output}" _output)
  STRING (STRIP "${_output}" ${retval})
ENDMACRO (_LSB_RELEASE)


# Returns a simple string describing the current platform. Possible
# return values currently include: windows_msvc; macosx; or any value
# from _DETERMINE_LINUX_DISTRO.
MACRO (_DETERMINE_PLATFORM var)
  IF (DEFINED CB_DOWNLOAD_DEPS_PLATFORM)
    SET (_plat ${CB_DOWNLOAD_DEPS_PLATFORM})
  ELSE (DEFINED CB_DOWNLOAD_DEPS_PLATFORM)
    SET (_plat ${CMAKE_SYSTEM_NAME})
    IF (_plat STREQUAL "Windows")
      SET (_plat "windows_msvc")
    ELSEIF (_plat STREQUAL "Darwin")
      SET (_plat "macosx")
    ELSEIF (_plat STREQUAL "Linux")
      FIND_PROGRAM(LSB_RELEASE lsb_release)
      IF (LSB_RELEASE)
        _DETERMINE_LINUX_DISTRO (_plat)
      ELSE (LSB_RELEASE)
        MESSAGE (WARNING "Can't determine Linux platform without lsb_release")
        SET (_plat "unknown")
      ENDIF (LSB_RELEASE)
    ELSEIF (_plat STREQUAL "SunOS")
      SET (_plat "sunos")
    ELSE (_plat STREQUAL "Windows")
      MESSAGE (WARNING "Sorry, don't recognize your system ${_plat}. ")
      SET (_plat "unknown")
    ENDIF (_plat STREQUAL "Windows")
    MESSAGE (STATUS "Set platform to ${_plat} for dependency downloads")
    SET (CB_DOWNLOAD_DEPS_PLATFORM ${_plat} CACHE STRING
      "Platform for downloaded dependencies")
    MARK_AS_ADVANCED (CB_DOWNLOAD_DEPS_PLATFORM)
  ENDIF (DEFINED CB_DOWNLOAD_DEPS_PLATFORM)
  SET (${var} ${_plat})
ENDMACRO (_DETERMINE_PLATFORM)


# Returns a simple string describing the current Linux distribution
# compatibility. Possible return values currently include:
# ubuntu14.04, ubuntu12.04, ubuntu10.04, centos5, centos6, debian7.
MACRO (_DETERMINE_LINUX_DISTRO _distro)
  _LSB_RELEASE (id _id)
  _LSB_RELEASE (release _rel)
  IF (_id STREQUAL "linuxmint")
    # Linux Mint is an Ubuntu derivative; estimate nearest Ubuntu equivalent
    SET (_id "ubuntu")
    IF (_rel VERSION_LESS 13)
      SET (_rel 10.04)
    ELSEIF (_rel VERSION_LESS 17)
      SET (_rel 12.02)
    ELSE (_rel VERSION_LESS 13)
      SET (_rel 14.04)
    ENDIF (_rel VERSION_LESS 13)
  ELSEIF (_id STREQUAL "debian" OR _id STREQUAL "centos" )
    # Just use the major version from the CentOS/Debian identifier - we don't
    # need different builds for different minor versions.
    STRING (REGEX MATCH "[0-9]+" _rel "${_rel}")
  ELSEIF (_id STREQUAL "fedora")
    SET (_id "centos")
    SET (_rel "7")
  ELSEIF (_id STREQUAL "opensuse project")
    SET(_id "opensuse")
  ENDIF (_id STREQUAL "linuxmint")
  SET (${_distro} "${_id}${_rel}")
ENDMACRO (_DETERMINE_LINUX_DISTRO)
