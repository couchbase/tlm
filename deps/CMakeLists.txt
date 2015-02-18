# Dependency downloads must be explicitly enabled
IF (NOT CB_DOWNLOAD_DEPS)
  RETURN ()
ENDIF (NOT CB_DOWNLOAD_DEPS)

INCLUDE (PlatformIntrospection)
INCLUDE (CBDownloadDeps)

MESSAGE (STATUS "*** Installing binary dependencies ***")
_DETERMINE_PLATFORM (cbcache_platform)
_DETERMINE_ARCH (cbcache_arch)

MESSAGE (STATUS "Set platform to ${cbcache_platform} for dependency downloads")
MESSAGE (STATUS "Set arch to ${cbcache_arch} for dependency downloads")

# Default personal override manifest is in user's home directory; may
# be overridden by CB_DOWNLOAD_DEPS_MANIFEST environment variable or
# by -DCB_DOWNLOAD_DEPS_MANIFEST on the CMake line.
IF (DEFINED ENV{CB_DOWNLOAD_DEPS_MANIFEST})
  SET (_manifest_default "$ENV{CB_DOWNLOAD_DEPS_MANIFEST}")
ELSEIF (WIN32)
  SET (_manifest_default "$ENV{HOMEPATH}/cbdepsmanifest.cmake")
ELSE (DEFINED ENV{CB_DOWNLOAD_DEPS_MANIFEST})
  # Linux / Mac
  SET (_manifest_default "$ENV{HOME}/cbdepsmanifest.cmake")
ENDIF (DEFINED ENV{CB_DOWNLOAD_DEPS_MANIFEST})
SET (CB_DOWNLOAD_DEPS_MANIFEST "${_manifest_default}" CACHE PATH
  "Path to user's override third-party dependencies manifest")
IF (EXISTS "${CB_DOWNLOAD_DEPS_MANIFEST}")
  MESSAGE (STATUS "-----------------------------------------")
  MESSAGE (STATUS "Reading personal third-party dependencies manifest "
    "from ${CB_DOWNLOAD_DEPS_MANIFEST}...")
  INCLUDE ("${CB_DOWNLOAD_DEPS_MANIFEST}")
  MESSAGE (STATUS "Personal third-party dependencies manifest complete")
  MESSAGE (STATUS "-----------------------------------------")
ENDIF (EXISTS "${CB_DOWNLOAD_DEPS_MANIFEST}")

# Read stock manifest
MESSAGE (STATUS "-----------------------------------------")
MESSAGE (STATUS "Reading global third-party dependencies manifest...")
INCLUDE (manifest.cmake)
MESSAGE (STATUS "Global third-party dependencies manifest complete")
MESSAGE (STATUS "-----------------------------------------")
