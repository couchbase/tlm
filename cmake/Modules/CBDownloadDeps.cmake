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
        MESSAGE (STATUS "Dependency ${name} (${dep_VERSION}) not declared for platform "
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

ENDIF (NOT CBDownloadDeps_INCLUDED)
