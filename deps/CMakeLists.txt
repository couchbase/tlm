# Dependency downloads must be explicitly enabled
IF (NOT CB_DOWNLOAD_DEPS)
  RETURN ()
ENDIF (NOT CB_DOWNLOAD_DEPS)

INCLUDE (PlatformIntrospection)
INCLUDE (CBDownloadDeps)

MESSAGE (STATUS "*** Installing binary dependencies ***")
_DETERMINE_PLATFORMS (cbcache_platform)
_DETERMINE_ARCH (cbcache_arch)

MESSAGE (STATUS "Set platform to ${cbcache_platform} for dependency downloads")
MESSAGE (STATUS "Set arch to ${cbcache_arch} for dependency downloads")

CB_GET_SUPPORTED_PLATFORM(_is_supported_platform)
IF (NOT _is_supported_platform)
  IF (CB_PRODUCTION_BUILD)
    MESSAGE (FATAL_ERROR "Attempt to run production build on unsupported platform!")
  ENDIF ()
  MESSAGE (STATUS "NOTE: The dependencies for unsupported platforms may not be available.")
  MESSAGE (STATUS "      Downloads may fail.")
  MESSAGE (STATUS "      You may try building dependencies by running \"make deps-all\" from the repo root.")
  MESSAGE (STATUS "      Individual dependencies can be built by running \"make dep-<dependency name>\".")
ENDIF ()

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
IF (NOT DEFINED CB_DOWNLOAD_DEPS_DEFAULT_MANIFEST)
    SET (CB_DOWNLOAD_DEPS_DEFAULT_MANIFEST manifest.cmake)
ENDIF ()
MESSAGE (STATUS "Reading global third-party dependencies manifest...")
INCLUDE ("${CB_DOWNLOAD_DEPS_DEFAULT_MANIFEST}")
MESSAGE (STATUS "Global third-party dependencies manifest complete")
MESSAGE (STATUS "-----------------------------------------")

# Update prefix path to include paths for all cbdeps for searching
GET_PROPERTY(_cbdeps_prefix_path GLOBAL PROPERTY CBDEPS_PREFIX_PATH)
SET(CMAKE_PREFIX_PATH "${_cbdeps_prefix_path};${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
