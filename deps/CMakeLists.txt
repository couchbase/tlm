# Dependency downloads must be explicitly enabled
IF (NOT CB_DOWNLOAD_DEPS)
  RETURN ()
ENDIF (NOT CB_DOWNLOAD_DEPS)

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
      execute_process(COMMAND isainfo -k
                      COMMAND tr -d '\n'
                      OUTPUT_VARIABLE _arch)
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


INCLUDE (ParseArguments)

# Given a file and a corresponding .md5 file, verify that the file's MD5
# checksum matches the contents of the .md5 file.
MACRO (_CHECK_MD5 file md5file retval)
  IF (NOT EXISTS "${md5file}")
    MESSAGE (FATAL_ERROR "Missing .md5 file ${md5file}!")
  ENDIF (NOT EXISTS "${md5file}")
  FILE (MD5 "${file}" _actual_md5)
  FILE (STRINGS "${md5file}" _expected_md5)
  IF (_actual_md5 STREQUAL _expected_md5)
    SET (${retval} 1)
  ELSE (_actual_md5 STREQUAL _expected_md5)
    SET (${retval} 0)
  ENDIF (_actual_md5 STREQUAL _expected_md5)
ENDMACRO (_CHECK_MD5)

# Downloads a file from a URL to a local file, raising any errors.
FUNCTION (_DOWNLOAD_FILE url file)
  FILE (DOWNLOAD "${url}" "${file}" STATUS _stat SHOW_PROGRESS)
  LIST (GET _stat 0 _retval)
  IF (_retval)
    # Don't leave corrupt/empty downloads
    IF (EXISTS "${file}")
      FILE (REMOVE "${file}")
    ENDIF (EXISTS "${file}")
    LIST (GET _stat 1 _message)
    MESSAGE (FATAL_ERROR "Error downloading ${url}: ${_message}")
  ENDIF (_retval)
ENDFUNCTION (_DOWNLOAD_FILE)

# Downloads a dependency to the cache dir. First checks the cache for
# an up-to-date copy based on md5.  Sets the global variable
# _CB_DOWNLOAD_CACHED_DEP to the downloaded dependency .tgz.
FUNCTION (_DOWNLOAD_DEP name version)
  _DETERMINE_PLATFORM (_platform)
  _DETERMINE_ARCH (_arch)

  # Compute relative paths to dependency, minus extension, on local filesystem
  # and in remote repository
  SET (_rel_path "${name}-${_platform}-${_arch}-${version}")
  SET (_repo_path
    "${CB_DOWNLOAD_DEPS_REPO}/${name}/${version}/${_rel_path}")

  SET (_cache_path "${CB_DOWNLOAD_DEPS_CACHE}/${_rel_path}")
  SET (_CB_DOWNLOAD_CACHED_DEP "${_cache_path}.tgz" PARENT_SCOPE)

  # If download file already exists, compare with md5
  IF (EXISTS "${_cache_path}.tgz")
    IF (EXISTS "${_cache_path}.md5")
      _CHECK_MD5 ("${_cache_path}.tgz" "${_cache_path}.md5" _md5equal)
      IF (_md5equal)
        MESSAGE (STATUS "Dependency '${name}' found in cache")
        RETURN ()
      ELSE (_md5equal)
        MESSAGE (WARNING "Cached download for dependency '${name}' has "
          "incorrect MD5! Will re-download!")
      ENDIF (_md5equal)
    ELSE (EXISTS "${_cache_path}.md5")
      MESSAGE (WARNING "Cached download for dependency '${name}' is missing "
        "md5 file! Will re-download!")
    ENDIF (EXISTS "${_cache_path}.md5")
  ENDIF (EXISTS "${_cache_path}.tgz")

  # File not found in cache or cache corrupt - download new.
  # First download the .md5.
  MESSAGE (STATUS "Downloading dependency md5: ${_rel_path}")
  _DOWNLOAD_FILE ("${_repo_path}.md5" "${_cache_path}.md5")
  MESSAGE (STATUS "Downloading dependency tgz: ${_rel_path}")
  _DOWNLOAD_FILE ("${_repo_path}.tgz" "${_cache_path}.tgz")
  _CHECK_MD5 ("${_cache_path}.tgz" "${_cache_path}.md5" _retval)
  IF (NOT _retval)
    MESSAGE (FATAL_ERROR "Downloaded file ${_cache_path}.tgz failed md5 sum check!")
  ENDIF (NOT _retval)
ENDFUNCTION (_DOWNLOAD_DEP)

# Declare a dependency
FUNCTION (DECLARE_DEP name)
  PARSE_ARGUMENTS (dep "PLATFORMS" "VERSION" "SKIP" ${ARGN})

  # If this dependency(+version) has already been declared, skip it
  if (dep_VERSION)
    SET (_prop_name "CB_DOWNLOADED_DEP_${name}_${dep_VERSION}")
  else (dep_VERSION)
    SET (_prop_name "CB_DOWNLOADED_DEP_${name}")
  endif(dep_VERSION)

  GET_PROPERTY (_declared GLOBAL PROPERTY ${_prop_name} SET)
  IF (_declared)
    MESSAGE (STATUS "Dependency ${name} already declared, skipping...")
    RETURN ()
  ENDIF (_declared)

  # If this dependency declares PLATFORM, ensure that we are running on
  # one of those platforms.
  _DETERMINE_PLATFORM (_this_platform)
  LIST (LENGTH dep_PLATFORMS _num_platforms)
  IF (_num_platforms GREATER 0)
    SET (_found_platform 0)
    FOREACH (_platform ${dep_PLATFORMS})
      IF ("${_this_platform}" STREQUAL "${_platform}")
        SET (_found_platform 1)
        BREAK ()
      ENDIF ("${_this_platform}" STREQUAL "${_platform}")
    ENDFOREACH (_platform)
    IF (NOT _found_platform)
      MESSAGE (STATUS "Dependency ${name} not declared for platform "
        "${_this_platform}, skipping...")
      RETURN ()
    ENDIF (NOT _found_platform)
  ENDIF (_num_platforms GREATER 0)

  # Remember that this dependency has been declared.
  SET_PROPERTY (GLOBAL PROPERTY ${_prop_name} 1)

  IF (dep_SKIP)
    MESSAGE (STATUS "Skipping download of dependency ${name} as requested")
    RETURN ()
  ENDIF (dep_SKIP)
  IF (NOT dep_VERSION)
    MESSAGE (FATAL_ERROR "Must specify either VERSION or SKIP for "
      "dependency '${name}' in dependency manifest.")
  ENDIF (NOT dep_VERSION)

  # Compute paths for exploded tgz and binary dir
  SET (_explode_dir "${CMAKE_CURRENT_BINARY_DIR}/${name}.exploded")
  SET (_binary_dir "${CMAKE_CURRENT_BINARY_DIR}/${name}.binary")

  # See if dependency is already downloaded. We assume the existence of a
  # VERSION file which matches the current version is sufficient.
  IF (EXISTS "${_explode_dir}/VERSION.txt")
    FILE (STRINGS "${_explode_dir}/VERSION.txt" EXPLODED_VERSION)
  ELSE (EXISTS "${_explode_dir}/VERSION.txt")
    SET (EXPLODED_VERSION "none")
  ENDIF (EXISTS "${_explode_dir}/VERSION.txt")

  IF (EXISTING_VERSION STREQUAL ${dep_VERSION})
      MESSAGE (STATUS "Dependency '${name} (${dep_VERSION})' already downloaded")
  ELSE (EXISTING_VERSION STREQUAL ${dep_VERSION})
    _DOWNLOAD_DEP (${name} ${dep_VERSION})

    # Explode tgz into build directory.
    MESSAGE (STATUS "Installing dependency: ${name}-${dep_VERSION}...")
    FILE (MAKE_DIRECTORY "${_explode_dir}")
    EXECUTE_PROCESS (COMMAND "${CMAKE_COMMAND}" -E 
      tar xf "${_CB_DOWNLOAD_CACHED_DEP}"
      WORKING_DIRECTORY "${_explode_dir}")
    FILE (WRITE ${_explode_dir}/VERSION.txt ${dep_VERSION})
  ENDIF (EXISTING_VERSION STREQUAL ${dep_VERSION})

  # Always add the dep subdir; this will "re-install" the dep every time you
  # run CMake, which might be wasteful, but at least should be safe.
  FILE (MAKE_DIRECTORY "${_binary_dir}")
  ADD_SUBDIRECTORY ("${_explode_dir}" "${_binary_dir}" EXCLUDE_FROM_ALL)

ENDFUNCTION (DECLARE_DEP)

SET (CB_DOWNLOAD_DEPS_REPO "http://packages.couchbase.com/couchbase-server/deps"
  CACHE STRING "URL of third-party dependency repository")

# Default download cache in user's home directory; may be overridden
# by CB_DOWNLOAD_DEPS_CACHE environment variable or by
# -DCB_DOWNLOAD_DEPS_CACHE on the CMake line.
IF (DEFINED ENV{CB_DOWNLOAD_DEPS_CACHE})
  SET (_cache_dir_default "$ENV{CB_DOWNLOAD_DEPS_CACHE}")
ELSEIF (WIN32)
  SET (_cache_dir_default "$ENV{HOMEPATH}/cbdepscache")
ELSE (DEFINED ENV{CB_DOWNLOAD_DEPS_CACHE})
  # Linux / Mac
  SET (_cache_dir_default "$ENV{HOME}/.cbdepscache")
ENDIF (DEFINED ENV{CB_DOWNLOAD_DEPS_CACHE})
SET (CB_DOWNLOAD_DEPS_CACHE "${_cache_dir_default}" CACHE PATH
  "Path to cache downloaded third-party dependencies")
FILE (MAKE_DIRECTORY "${CB_DOWNLOAD_DEPS_CACHE}")
MESSAGE (STATUS "Third-party dependencies will be cached in "
  "${CB_DOWNLOAD_DEPS_CACHE}")

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

