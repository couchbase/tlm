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
      LIST (GET _stat 0 _errcode)
      LIST (GET _stat 1 _message)
      MESSAGE (FATAL_ERROR "Error downloading ${url}: ${_message} (${_errcode})")
    ENDIF (_retval)
  ENDFUNCTION (_DOWNLOAD_FILE)

  # Downloads a specific URL to a file with the same name in the cache dir.
  # First checks the cache for an up-to-date copy based on md5.
  # Sets the variable named by "var" to the locally-cached path.
  FUNCTION (_DOWNLOAD_URL_TO_CACHE url var)
    # Compute local name for cache.
    GET_FILENAME_COMPONENT (_file "${url}" NAME)
    SET (_md5file "${_file}.md5")

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

    # First compute the URL for the .md5 and download it. For historical
    # reasons, if the url's extension is ".tgz", the MD5 url will be same as
    # the url with ".tgz" replaced by ".md5". Otherwise, the MD5 url will
    # simply be the url with an additional ".md5" extension.
    IF (url MATCHES "\\.tgz$")
      STRING (REGEX REPLACE "\\.tgz$" ".md5" _md5url "${url}")
    ELSE ()
      SET (_md5url "${_url}.md5")
    ENDIF ()
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
          MESSAGE (STATUS "Dependency '${path}' found in cache")
          SET(${var} TRUE PARENT_SCOPE)
          RETURN ()
        ELSE (_md5equal)
          MESSAGE (WARNING "Cached download for dependency '${path}' has "
            "incorrect MD5! Will re-download!")
        ENDIF (_md5equal)
      ELSE (EXISTS "${md5path}")
        MESSAGE (WARNING "Cached download for dependency '${md5path}' is missing "
          "md5 file! Will re-download!")
      ENDIF (EXISTS "${md5path}")
    ENDIF (EXISTS "${path}")
  ENDFUNCTION ()

  FUNCTION (_GET_DEP_FILENAME name version var)
    _DETERMINE_PLATFORM (_platform)
    _DETERMINE_ARCH (_arch)

    # Compute relative paths to dependency on local filesystem
    # and in remote repository
    SET (${var} "${name}-${_platform}-${_arch}-${version}.tgz" PARENT_SCOPE)
  ENDFUNCTION ()

  # Downloads a dependency to the cache dir. First checks the cache for
  # an up-to-date copy based on md5.  Sets the variable named by 'var'
  # to the downloaded dependency .tgz.
  FUNCTION (_DOWNLOAD_DEP name version var)
    _GET_DEP_FILENAME("${name}" "${version}" _rel_path)
    SET (_repo_url "${CB_DOWNLOAD_DEPS_REPO}/${name}/${version}/${_rel_path}")
    _DOWNLOAD_URL_TO_CACHE ("${_repo_url}" _cachefile)
    SET (${var} "${_cachefile}" PARENT_SCOPE)
  ENDFUNCTION (_DOWNLOAD_DEP)

  # Unpack an archive file into a directory, with error checking.
  FUNCTION (EXPLODE_ARCHIVE file dir)
    FILE (MAKE_DIRECTORY "${dir}")
    EXECUTE_PROCESS (COMMAND "${CMAKE_COMMAND}" -E
      tar xf "${file}"
      WORKING_DIRECTORY "${dir}"
      RESULT_VARIABLE _explode_result
      ERROR_VARIABLE _explode_stderr)
    IF(_explode_result)
      FILE (REMOVE_RECURSE "${dir}")
      FILE (REMOVE "${file}")
      MESSAGE (FATAL_ERROR "Failed to extract dependency ${file} - file corrupt? "
        "It has been deleted, please try again.\n ${_explode_stderr}")
    ENDIF(_explode_result)
  ENDFUNCTION (EXPLODE_ARCHIVE)

  # Declare a dependency
  FUNCTION (DECLARE_DEP name)
    PARSE_ARGUMENTS (dep "PLATFORMS" "VERSION" "SKIP" ${ARGN})

    # If this dependency has already been declared, skip it
    SET (_prop_name "CB_DOWNLOADED_DEP_${name}")
    GET_PROPERTY (_declared GLOBAL PROPERTY ${_prop_name} SET)
    IF (_declared)
      MESSAGE (STATUS "Dependency ${name} already declared, skipping...")
      RETURN ()
    ENDIF (_declared)

    # If this dependency declares PLATFORM, ensure that we are running on
    # one of those platforms.
    _DETERMINE_PLATFORM (_this_platform)
    GET_SUPPORTED_PRODUCTION_PLATFORM (_supported_platform)
    LIST (LENGTH dep_PLATFORMS _num_platforms)
    IF (_num_platforms GREATER 0)
      SET (_found_platform 0)
      FOREACH (_platform ${dep_PLATFORMS})
        IF ("${_this_platform}" STREQUAL "${_platform}")
          SET (_found_platform 1)
          BREAK ()
        ENDIF ("${_this_platform}" STREQUAL "${_platform}")
      ENDFOREACH (_platform)
      IF (NOT _found_platform AND NOT _supported_platform)
        # check if we maybe have locally built dep file
        _GET_DEP_FILENAME("${name}" "${dep_VERSION}" _dep_filename)
        SET(_dep_path "${CB_DOWNLOAD_DEPS_CACHE}/${_dep_filename}")
        SET(_dep_md5path "${CB_DOWNLOAD_DEPS_CACHE}/${_dep_filename}.md5")

        _CHECK_CACHED_DEP_FILE("${_dep_path}" "${_dep_md5path}" _dep_found)

        IF (_dep_found)
          MESSAGE (STATUS "Found locally built dependency file ${_dep_path}. "
            "Going to use it even though the platform ${_this_platform} is unsupported")
          SET (_found_platform 1)
        ENDIF ()
      ENDIF (NOT _found_platform AND NOT _supported_platform)
      IF (NOT _found_platform)
        MESSAGE (STATUS "Dependency ${name} (${dep_VERSION}) not declared for platform "
          "${_this_platform}, skipping...")
        RETURN ()
      ENDIF ()
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
      SET (EXPLODED_VERSION "<none>")
    ENDIF (EXISTS "${_explode_dir}/VERSION.txt")

    MESSAGE (STATUS "Checking exploded ${name} version ${EXPLODED_VERSION} against ${dep_VERSION}")
    IF (EXPLODED_VERSION STREQUAL ${dep_VERSION})
      MESSAGE (STATUS "Dependency '${name} (${dep_VERSION})' already downloaded")
    ELSE (EXPLODED_VERSION STREQUAL ${dep_VERSION})
      _DOWNLOAD_DEP (${name} ${dep_VERSION} _cachedep)

      # Explode tgz into build directory.
      MESSAGE (STATUS "Installing dependency: ${name}-${dep_VERSION}...")
      EXPLODE_ARCHIVE ("${_cachedep}" "${_explode_dir}")
      FILE (WRITE "${_explode_dir}/VERSION.txt" ${dep_VERSION})
    ENDIF (EXPLODED_VERSION STREQUAL ${dep_VERSION})

    # Always add the dep subdir; this will "re-install" the dep every time you
    # run CMake, which might be wasteful, but at least should be safe.
    FILE (MAKE_DIRECTORY "${_binary_dir}")
    IF (EXISTS ${_explode_dir}/CMakeLists.txt)
      ADD_SUBDIRECTORY ("${_explode_dir}" "${_binary_dir}" EXCLUDE_FROM_ALL)
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
      IF ("${GOVERSION}" MATCHES "^1.4.[0-9]+$")
        SET (_gofile "go${GOVERSION}.darwin-amd64-osx10.8.tar.gz")
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
      SET (_gofile "go${GOVERSION}.linux-amd64.tar.gz")
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
      MESSAGE (FATAL_ERROR "Downloaded go archive ${_gofile}"
        " failed to unpack correctly - ${_goexe} does not exist!")
    ENDIF ()
  ENDFUNCTION (GET_GO_VERSION)

  SET (CB_DOWNLOAD_DEPS_REPO "http://packages.couchbase.com/couchbase-server/deps"
    CACHE STRING "URL of third-party dependency repository")
  SET (GO_DOWNLOAD_REPO "http://storage.googleapis.com/golang"
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
