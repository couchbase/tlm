IF (NOT CBDownloadDeps_INCLUDED)
  SET (CBDownloadDeps_INCLUDED 1)

  INCLUDE (ParseArguments)
  INCLUDE (PlatformIntrospection)

  # Given a file and a corresponding .md5 file, verify that the file's MD5
  # checksum matches the contents of the .md5 file.
  MACRO (_CHECK_MD5 file md5file retval)
    IF (NOT EXISTS "${md5file}")
      MESSAGE (FATAL_ERROR "Missing .md5 file ${md5file}!")
    ENDIF (NOT EXISTS "${md5file}")
    FILE (MD5 "${file}" _actual_md5)
    FILE (READ "${md5file}" _expected_md5_output LIMIT 32)
    STRING (SUBSTRING "${_expected_md5_output}" 0 32 _expected_md5)
    IF (_actual_md5 STREQUAL _expected_md5)
      SET (${retval} 1)
    ELSE (_actual_md5 STREQUAL _expected_md5)
      SET (${retval} 0)
    ENDIF (_actual_md5 STREQUAL _expected_md5)
  ENDMACRO (_CHECK_MD5)

  # Downloads a file from a URL to a local file, raising any errors.
  FUNCTION (_DOWNLOAD_FILE url file)
    FILE (DOWNLOAD "${url}" "${file}.temp" STATUS _stat SHOW_PROGRESS)
    LIST (GET _stat 0 _retval)
    IF (_retval)
      FILE (REMOVE "${file}.temp")
      LIST (GET _stat 0 _errcode)
      LIST (GET _stat 1 _message)
      MESSAGE (FATAL_ERROR "Error downloading ${url}: ${_message} (${_errcode})")
    ENDIF (_retval)
    FILE (RENAME "${file}.temp" "${file}")
  ENDFUNCTION (_DOWNLOAD_FILE)

  # Downloads a specific URL to a file with the same name in the cache dir.
  # First checks the cache for an up-to-date copy based on md5.
  # Sets the variable named by "var" to the locally-cached path.
  FUNCTION (_DOWNLOAD_URL_TO_CACHE url var)
    # First compute the URL for the .md5. For historical reasons, if the
    # url's extension is ".tgz", the MD5 url will be same as the url with
    # ".tgz" replaced by ".md5". Otherwise, the MD5 url will simply be the url
    # with an additional ".md5" extension.
    IF (url MATCHES "\\.tgz$")
      STRING (REGEX REPLACE "\\.tgz$" ".md5" _md5url "${url}")
    ELSE ()
      SET (_md5url "${_url}.md5")
    ENDIF ()

    # Compute local filenames for cache.
    GET_FILENAME_COMPONENT (_file "${url}" NAME)
    GET_FILENAME_COMPONENT (_md5file "${_md5url}" NAME)

    # Compute local full paths to cached files.
    SET (_cache_file_path "${CB_DOWNLOAD_DEPS_CACHE}/${_file}")
    SET (_cache_md5file_path "${CB_DOWNLOAD_DEPS_CACHE}/${_md5file}")

    # "Return" the cached file path.
    SET (${var} "${_cache_file_path}" PARENT_SCOPE)

    _CHECK_CACHED_DEP_FILE("${_cache_file_path}" "${_cache_md5file_path}" _found_cached)

    IF (_found_cached)
      RETURN ()
    ENDIF (_found_cached)

    # File not found in cache or cache corrupt - download new.

    MESSAGE (STATUS "Downloading dependency md5: ${_md5file}")
    _DOWNLOAD_FILE ("${_md5url}" "${_cache_md5file_path}")
    MESSAGE (STATUS "Downloading dependency: ${_file}")
    _DOWNLOAD_FILE ("${url}" "${_cache_file_path}")
    _CHECK_MD5 ("${_cache_file_path}" "${_cache_md5file_path}" _md5equal)
    IF (NOT _md5equal)
      MESSAGE (FATAL_ERROR "Downloaded file ${_cache_file_path} failed md5 sum check!")
    ENDIF ()
  ENDFUNCTION (_DOWNLOAD_URL_TO_CACHE)

  FUNCTION (_CHECK_CACHED_DEP_FILE path md5path var)
    SET(${var} FALSE PARENT_SCOPE)

    IF (EXISTS "${path}")
      IF (EXISTS "${md5path}")
        _CHECK_MD5 ("${path}" "${md5path}" _md5equal)
        IF (_md5equal)
          SET(${var} TRUE PARENT_SCOPE)
          RETURN ()
        ELSE ()
          MESSAGE (WARNING "Cached download for dependency '${path}' has "
            "incorrect MD5! Will re-download!")
        ENDIF ()
      ELSE (EXISTS "${md5path}")
        MESSAGE (WARNING "Cached download for dependency '${path}' is missing "
          "md5 file! Will re-download!")
      ENDIF (EXISTS "${md5path}")
    ENDIF (EXISTS "${path}")
  ENDFUNCTION ()

  FUNCTION (_GET_DEP_FILENAME name version platform var)
    # Special case for "all" platform - must be "noarch"
    IF ("${platform}" STREQUAL "all")
      SET (_arch "noarch")
    ELSE ()
      _DETERMINE_ARCH (_arch)
    ENDIF ()

    # Compute relative paths to dependency on local filesystem
    # and in remote repository
    SET (${var} "${name}-${platform}-${_arch}-${version}.tgz" PARENT_SCOPE)
  ENDFUNCTION ()

  # Downloads a dependency to the cache dir. First checks the cache for
  # an up-to-date copy based on md5.  Sets the variable named by 'var'
  # to the downloaded dependency .tgz.
  FUNCTION (_DOWNLOAD_DEP name v2 version build platform var)
    IF (v2)
      _GET_DEP_FILENAME("${name}" "${version}-${build}" ${platform} _rel_path)
      SET (_repo_url "${CB_DOWNLOAD_DEPS_REPO}/${name}/${version}/${build}/${_rel_path}")
    ELSE (v2)
      _GET_DEP_FILENAME("${name}" "${version}" ${platform} _rel_path)
      SET (_repo_url "${CB_DOWNLOAD_DEPS_REPO}/${name}/${version}/${_rel_path}")
    ENDIF (v2)
    _DOWNLOAD_URL_TO_CACHE ("${_repo_url}" _cachefile)
    SET (${var} "${_cachefile}" PARENT_SCOPE)
  ENDFUNCTION (_DOWNLOAD_DEP)

  # Unpack an archive file into a directory, with error checking.
  FUNCTION (EXPLODE_ARCHIVE file dir)
    SET (temp_dir "${dir}.temp")
    FILE (REMOVE_RECURSE "${temp_dir}")
    FILE (MAKE_DIRECTORY "${temp_dir}")
    MESSAGE (STATUS "Extracting ${file} to ${temp_dir}")
    EXECUTE_PROCESS (COMMAND "${CMAKE_COMMAND}" -E
      tar xf "${file}"
      WORKING_DIRECTORY "${temp_dir}"
      RESULT_VARIABLE _explode_result
      ERROR_VARIABLE _explode_stderr)
    STRING (FIND "${_explode_stderr}" "error" _explode_error)
    IF(_explode_result GREATER 0 OR _explode_error GREATER -1)
      FILE (REMOVE_RECURSE "${dir}")
      FILE (REMOVE_RECURSE "${temp_dir}")
      FILE (REMOVE "${file}")
      MESSAGE (FATAL_ERROR "Failed to extract dependency ${file} - file corrupt? "
        "It has been deleted, please try again.\n ${_explode_stderr}")
    ENDIF()
    MESSAGE(STATUS "Moving ${temp_dir} to ${dir}")
    FILE (REMOVE_RECURSE "${dir}")
    FILE (RENAME "${temp_dir}" "${dir}")
  ENDFUNCTION (EXPLODE_ARCHIVE)

  # Declare a dependency
  FUNCTION (DECLARE_DEP name)
    PARSE_ARGUMENTS (dep "PLATFORMS" "VERSION;BUILD;DESTINATION" "V2;SKIP;NOINSTALL;GO_DEP;ALLOW_MULTIPLE" ${ARGN})

    # Error check: ALLOW_MULTIPLE requires DESTINATION, since otherwise
    # the multiple downloaded versions will be unpacked into the same
    # .exploded directory.
    IF (dep_ALLOW_MULTIPLE AND "${dep_DESTINATION}" STREQUAL "")
      MESSAGE (FATAL_ERROR "Cannot use ALLOW_MULTIPLE without DESTINATION")
    ENDIF ()

    # If this dependency has already been declared, skip it.
    # Exception: if we are building the cbdeps packages themselves then
    # allow duplicates; as each cbdep may need the package for it's
    # own build.
    SET (_prop_name "CB_DOWNLOADED_DEP_${name}")
    GET_PROPERTY (_declared GLOBAL PROPERTY ${_prop_name} SET)
    IF (_declared
        AND NOT dep_ALLOW_MULTIPLE
        AND NOT "${PROJECT_NAME}" STREQUAL "cbdeps_packages")
      MESSAGE (STATUS "Dependency ${name} already declared, skipping...")
      RETURN ()
    ENDIF ()

    # Set a variable to use for the version. Also cache the version and build
    # number for use by other parts of the build.
    IF (dep_V2)
      # for V2, version and build number values are separate arguments
      SET (_dep_version "${dep_VERSION}")
      SET (_dep_bld_num "${dep_BUILD}")
    ELSE (dep_V2)
      # for V1, version is conventionally version-bld_num, so split it apart.
      # Occasionally there may be a version with no -, in which case the
      # bld_num is the empty string.
      # Additionally the version component can include '-', so we only
      # want to split on the last '-' in it.
      STRING (FIND ${dep_VERSION} "-" _last_hyphen_pos REVERSE)
      IF (_last_hyphen_pos GREATER 0)
        # Build number present, split version at that point.
        STRING (SUBSTRING ${dep_VERSION} 0 ${_last_hyphen_pos} _dep_version)
        MATH (EXPR bld_num_start "${_last_hyphen_pos} + 1")
        STRING (SUBSTRING ${dep_VERSION} ${bld_num_start} -1 _dep_bld_num)
      ELSE()
        # No build number, just set version and leave bld_num empty.
        SET (_dep_bld_num ${dep_VERSION})
      ENDIF()
    ENDIF (dep_V2)
    SET (_dep_fullver "${_dep_version}-${_dep_bld_num}")
    SET (CBDEP_${name}_VERSION "${_dep_version}" CACHE STRING "Version of cbdep package '${name}'" FORCE)
    SET (CBDEP_${name}_BLD_NUM "${_dep_bld_num}" CACHE STRING "Build number of cbdep package '${name}'" FORCE)

    # Match up the platforms the dependency is declared for with the
    # set of platform descriptors for our local environment.
    _DETERMINE_PLATFORMS (_local_platforms)
    CB_GET_SUPPORTED_PLATFORM (_is_supported_platform)
    SET (_found_platform "")
    FOREACH (_platform ${dep_PLATFORMS})
      IF ("${_platform}" IN_LIST _local_platforms)
        SET (_found_platform ${_platform})
        BREAK ()
      ENDIF ()
    ENDFOREACH (_platform)
    IF (NOT _found_platform AND NOT _is_supported_platform)
      # check if we maybe have locally built dep file
      _DETERMINE_PLATFORM (_local_platform)
      _GET_DEP_FILENAME("${name}" "${_dep_fullver}" ${_local_platform} _dep_filename)
      SET(_dep_path "${CB_DOWNLOAD_DEPS_CACHE}/${_dep_filename}")
      STRING(REGEX REPLACE "\\.tgz$" ".md5" _dep_md5path "${_dep_path}")
      _CHECK_CACHED_DEP_FILE("${_dep_path}" "${_dep_md5path}" _dep_found)
      IF (_dep_found)
        MESSAGE (STATUS "Found locally built dependency file ${_dep_path}. "
          "Going to use it even though the platform ${_local_platforms} is unsupported")
        SET (_found_platform "${_local_platform}")
      ENDIF ()
    ENDIF ()
    IF (NOT _found_platform)
      MESSAGE (STATUS "Dependency ${name} (${_dep_fullver}) not declared for platform "
        "${_local_platforms}, skipping...")
      RETURN ()
    ENDIF ()

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
    IF (dep_DESTINATION)
      SET (_explode_dir "${dep_DESTINATION}")
    ELSE ()
      SET (_explode_dir "${CMAKE_CURRENT_BINARY_DIR}/${name}.exploded")
    ENDIF ()
    SET (_binary_dir "${CMAKE_CURRENT_BINARY_DIR}/${name}.binary")

    # See if dependency is already downloaded. We assume the existence of a
    # VERSION file which matches the current version is sufficient.
    IF (EXISTS "${_explode_dir}/VERSION.txt")
      FILE (STRINGS "${_explode_dir}/VERSION.txt" EXPLODED_VERSION)
    ELSE (EXISTS "${_explode_dir}/VERSION.txt")
      SET (EXPLODED_VERSION "<none>")
    ENDIF (EXISTS "${_explode_dir}/VERSION.txt")

    MESSAGE (STATUS "Checking exploded ${name} version ${EXPLODED_VERSION} against ${_dep_fullver}")
    IF (EXPLODED_VERSION STREQUAL ${_dep_fullver})
      MESSAGE (STATUS "Dependency '${name} (${_dep_fullver})' already downloaded")
    ELSE ()
      _DOWNLOAD_DEP ("${name}" "${dep_V2}" "${dep_VERSION}" "${dep_BUILD}" ${_found_platform} _cachedep)

      # Explode tgz into build directory.
      MESSAGE (STATUS "Installing dependency: ${name}-${_dep_fullver}...")
      EXPLODE_ARCHIVE ("${_cachedep}" "${_explode_dir}")
      FILE (WRITE "${_explode_dir}/VERSION.txt" ${_dep_fullver})
    ENDIF ()

    # If this is a Go-built cbdeps package, extract the Go version to save
    # in the go-versions.yaml report
    IF (${dep_GO_DEP})
      FILE (STRINGS "${_explode_dir}/META/go-version.txt" _gover LIMIT_COUNT 1)
      # We don't keep track of the "requested Go version", as it's not very
      # interesting after the cbdeps build. We use the cbdeps name as the
      # TARGET; "cbdeps-build" as the USAGE; and assume UNSHIPPED is false.
      SAVE_GO_TARGET (${_gover} ${_gover} ${name} "cbdeps-build" 0)
    ENDIF ()

    # Always add the dep subdir; this will "re-install" the dep every time you
    # run CMake, which might be wasteful, but at least should be safe.
    IF (EXISTS ${_explode_dir}/CMakeLists.txt)
      IF (dep_NOINSTALL)
        MESSAGE(STATUS "Skip running CMakeLists from the package")
      ELSE (dep_NOINSTALL)
        # Add the dep subdir; this will "re-install" the dep every time you
        # run CMake, which might be wasteful, but at least should be safe.
        FILE (MAKE_DIRECTORY "${_binary_dir}")
        ADD_SUBDIRECTORY ("${_explode_dir}" "${_binary_dir}" EXCLUDE_FROM_ALL)
      ENDIF (dep_NOINSTALL)
    ELSE ()
      # If the package doesn't include a CMakeLists.txt itself, for convenience,
      # set the "modern CMake" variable `dep_ROOT` to this directory.
      SET (${name}_ROOT "${_explode_dir}" CACHE PATH "Root of ${name}" FORCE)
    ENDIF (EXISTS ${_explode_dir}/CMakeLists.txt)
  ENDFUNCTION (DECLARE_DEP)

  # Download and cache a specific version of Go, and explode it into the
  # *cache* directory. Sets the variable named by "var" to point to
  # the GOROOT in the exploded directory.
  FUNCTION (GET_GO_VERSION GOVERSION var)
    # Unlike DOWNLOAD_DEP(), we explode Go downloads into the cache directory,
    # not the binary directory. This means we don't need to re-explode it
    # every time we clean the binary directory. We could do the same for
    # other downloaded deps (and probably should), but we have less control
    # other whether any parts of the build do naughty things like modify the
    # exploded dep contents.
    _DETERMINE_ARCH (_arch)
    SET (_explode_dir "${CB_DOWNLOAD_DEPS_CACHE}/exploded/${_arch}/go-${GOVERSION}")
    SET (_goroot "${_explode_dir}/go")
    IF (WIN32)
      SET (_goexe "${_goroot}/bin/go.exe")
    ELSE ()
      SET (_goexe "${_goroot}/bin/go")
    ENDIF ()
    SET (${var} "${_goroot}" PARENT_SCOPE)

    # We assume the go binary existing is sufficient to say that the requested
    # go version has been downloaded successfully.
    IF (EXISTS "${_goexe}")
      RETURN ()
    ENDIF ()

    # Otherwise, download the correct version for the current platform.
    _DETERMINE_PLATFORM (_platform)
    STRING (SUBSTRING "${_platform}" 0 6 _platform_head)
    IF (_platform STREQUAL "macosx")
      IF (_arch STREQUAL "arm64")
        SET (GO_MAC_MINIMUM_VERSION 1.16.3)
        SET (_gofile "go${GOVERSION}.darwin-${_arch}.tar.gz")
      ELSE ()
        SET (_gofile "go${GOVERSION}.darwin-amd64.tar.gz")
      ENDIF ()
    ELSEIF (_platform_head STREQUAL "window")
      IF (_arch STREQUAL "x86")
        SET (_arch "386")
      ENDIF ()
      SET (_gofile "go${GOVERSION}.windows-${_arch}.zip")
    ELSEIF (_platform STREQUAL "freebsd")
      SET (_gofile "go${GOVERSION}.freebsd-amd64.tar.gz")
    ELSE ()
      # Presumed Linux
      IF (_arch STREQUAL "aarch64")
        SET (_gofile "go${GOVERSION}.linux-arm64.tar.gz")
      ELSE ()
        SET (_gofile "go${GOVERSION}.linux-amd64.tar.gz")
      ENDIF ()
    ENDIF ()
    SET (_cachefile "${CB_DOWNLOAD_DEPS_CACHE}/${_gofile}")
    IF (NOT EXISTS "${_cachefile}")
      MESSAGE (STATUS "Golang version ${GOVERSION} not found in cache, "
        "downloading...")
      _DOWNLOAD_FILE ("${GO_DOWNLOAD_REPO}/${_gofile}" "${_cachefile}")
    ENDIF ()
    MESSAGE (STATUS "Installing Golang version ${GOVERSION} in cache...")
    EXPLODE_ARCHIVE ("${_cachefile}" "${_explode_dir}")

    IF (NOT EXISTS "${_goexe}")
      FILE (REMOVE "${_cachefile}")
      FILE (REMOVE_RECURSE "${_explode_dir}")
      MESSAGE (FATAL_ERROR "Downloaded go archive ${_gofile}"
        " failed to unpack correctly - ${_goexe} does not exist!"
        " (archive removed from download cache)")
    ENDIF ()
  ENDFUNCTION (GET_GO_VERSION)

  # Start of CBDeps 2.0 - download and cache the new 'cbdep' tool
  SET (CBDEP_VERSION 1.1.7)
  FUNCTION (GET_CBDEP)
    _DETERMINE_PLATFORM (_platform)
    _DETERMINE_ARCH (_arch)
    STRING (SUBSTRING "${_platform}" 0 6 _platform_head)
    IF (_platform STREQUAL "macosx")
      SET (_cbdepfile "cbdep-${CBDEP_VERSION}-darwin-${_arch}")
    ELSEIF (_platform_head STREQUAL "window")
      SET (_cbdepfile "cbdep-${CBDEP_VERSION}-windows.exe")
    ELSE ()
      # Presumed Linux
      SET (_cbdepfile "cbdep-${CBDEP_VERSION}-linux-${_arch}")
    ENDIF ()
    SET (CBDEP_CACHE "${CB_DOWNLOAD_DEPS_CACHE}/cbdep/${CBDEP_VERSION}/${_cbdepfile}"
      CACHE INTERNAL "Path to cbdep cached download")
    SET (CBDEP "${PROJECT_BINARY_DIR}/tlm/${_cbdepfile}"
      CACHE INTERNAL "Path to cbdep executable")
    IF (NOT EXISTS "${CBDEP_CACHE}")
      MESSAGE (STATUS "Downloading cbdep ${CBDEP_VERSION}")
      _DOWNLOAD_FILE (
        "https://packages.couchbase.com/cbdep/${CBDEP_VERSION}/${_cbdepfile}"
        "${CBDEP_CACHE}")
    ENDIF ()
    IF (NOT EXISTS "${CBDEP}")
      FILE (COPY "${CBDEP_CACHE}" DESTINATION "${PROJECT_BINARY_DIR}/tlm"
        FILE_PERMISSIONS OWNER_EXECUTE OWNER_READ OWNER_WRITE)
      MESSAGE (STATUS "Using cbdep at ${CBDEP}")
    ENDIF ()
  ENDFUNCTION (GET_CBDEP)

  # Generic function for installing a cbdep (2.0) package to a given directory
  # Required arguments:
  #   PACKAGE - package to install
  #   VERSION - version number of package (must be understood by 'cbdep' tool)
  # Optional arguments:
  #   INSTALL_DIR - where to install to; defaults to CMAKE_CURRENT_BINARY_DIR
  MACRO (CBDEP_INSTALL)
    PARSE_ARGUMENTS (cbdep "" "INSTALL_DIR;PACKAGE;VERSION" "" ${ARGN})

    GET_CBDEP ()

    IF (NOT cbdep_INSTALL_DIR)
      SET (cbdep_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    ENDIF ()
    IF(NOT IS_DIRECTORY "${cbdep_INSTALL_DIR}/${cbdep_PACKAGE}-${cbdep_VERSION}")
      MESSAGE (STATUS "Downloading and caching ${cbdep_PACKAGE}-${cbdep_VERSION}")
      EXECUTE_PROCESS (
        COMMAND "${CBDEP}" install
          -d "${cbdep_INSTALL_DIR}"
          ${cbdep_PACKAGE} ${cbdep_VERSION}
        RESULT_VARIABLE _cbdep_result
        OUTPUT_VARIABLE _cbdep_out
        ERROR_VARIABLE _cbdep_out
      )
      IF (_cbdep_result)
        FILE (REMOVE_RECURSE "${cbdep_INSTALL_DIR}")
        MESSAGE (FATAL_ERROR "Failed installing cbdep ${cbdep_PACKAGE} ${cbdep_VERSION}: ${_cbdep_out}")
      ENDIF ()
    ENDIF()
  ENDMACRO (CBDEP_INSTALL)

  CB_GET_SUPPORTED_PLATFORM (_is_supported_platform)
  IF (_is_supported_platform)
    SET (CB_DOWNLOAD_DEPS_REPO
      "https://packages.couchbase.com/couchbase-server/deps"
      CACHE STRING "URL of third-party dependency repository")
  ELSE ()
    SET (CB_DOWNLOAD_DEPS_REPO
      "https://packages.couchbase.com/couchbase-server/deps-unsupported"
      CACHE STRING "URL of third-party dependency repository")
  ENDIF ()
  SET (GO_DOWNLOAD_REPO "https://storage.googleapis.com/golang"
    CACHE STRING "URL of Golang downloads repository")

  # Default download cache in user's home directory; may be overridden
  # by CB_DOWNLOAD_DEPS_CACHE environment variable or by
  # -DCB_DOWNLOAD_DEPS_CACHE on the CMake line.
  IF (DEFINED ENV{CB_DOWNLOAD_DEPS_CACHE})
    SET (_cache_dir_default "$ENV{CB_DOWNLOAD_DEPS_CACHE}")
  ELSEIF (WIN32)
    SET (_cache_dir_default "$ENV{HOMEDRIVE}/$ENV{HOMEPATH}/cbdepscache")
  ELSE (DEFINED ENV{CB_DOWNLOAD_DEPS_CACHE})
    # Linux / Mac
    SET (_cache_dir_default "$ENV{HOME}/.cbdepscache")
  ENDIF (DEFINED ENV{CB_DOWNLOAD_DEPS_CACHE})
  SET (CB_DOWNLOAD_DEPS_CACHE "${_cache_dir_default}" CACHE PATH
    "Path to cache downloaded third-party dependencies")
  FILE (MAKE_DIRECTORY "${CB_DOWNLOAD_DEPS_CACHE}")
  MESSAGE (STATUS "Third-party dependencies will be cached in "
    "${CB_DOWNLOAD_DEPS_CACHE}")
ENDIF (NOT CBDownloadDeps_INCLUDED)
