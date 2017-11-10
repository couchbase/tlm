IF (NOT FindCouchbaseJava_INCLUDED)

  # This is where the version of Java we use for production builds
  # is declared.
  SET (_jdk_major 8)
  SET (_jdk_update 152)
  SET (_jdk_build b16)
  SET (_jdk_hash aa0333dd3019491ca4f6ddbe78cdb6d0)

  INCLUDE (CBDownloadDeps)

  OPTION (CB_DOWNLOAD_JAVA "Whether to download specific JDK on non-production builds" OFF)

  _DETERMINE_PLATFORM (_platform)
  STRING (SUBSTRING "${_platform}" 0 6 _platform_head)

  FUNCTION (_DOWNLOAD_JDK jdk_ver var)
    SET (_jdk_baseurl "http://download.oracle.com/otn-pub/java/jdk")
    IF (_platform_head STREQUAL "window")
      SET (_jdk_file "jdk-${jdk_ver}-windows-x64.exe")
    ELSEIF (_platform STREQUAL "macosx")
      SET (_jdk_file "jdk-${jdk_ver}-macosx-x64.dmg")
    ELSE ()
      # Presumed Linux
      SET (_jdk_file "jdk-${jdk_ver}-linux-x64.tar.gz")
    ENDIF ()
    SET (_jdk_cachefile "${CB_DOWNLOAD_DEPS_CACHE}/${_jdk_file}")
    SET (_jdk_url "${_jdk_baseurl}/${jdk_ver}-${_jdk_build}/${_jdk_hash}/${_jdk_file}")

    # Download JDK from Oracle. Save in user's cbdeps cache.
    FIND_PROGRAM(CURL_BINARY
                 NAMES curl
                 HINTS "${CMAKE_BINARY_DIR}/tlm/deps/curl.exploded"
                       ENV CURL_DIR)
    IF (NOT CURL_BINARY)
      MESSAGE (FATAL_ERROR "Sorry, need curl to download JDK :(")
    ENDIF ()

    # The cbdeps curl doesn't know how to find its own lib
    INCLUDE (FindCouchbaseCurl)
    GET_FILENAME_COMPONENT (_curl_libdir "${CURL_LIBRARIES}" DIRECTORY)
    SET (_orig_ldlibpath $ENV{LD_LIBRARY_PATH})
    SET (ENV{LD_LIBRARY_PATH} "${_curl_libdir}")

    MESSAGE (STATUS "Downloading Oracle JDK ${jdk_ver}...")
    EXECUTE_PROCESS (
      COMMAND "${CURL_BINARY}" --continue - --location
        --remote-time --remote-name --insecure
        --cookie oraclelicense=accept-securebackup-cookie
        "${_jdk_url}"
      WORKING_DIRECTORY "${CB_DOWNLOAD_DEPS_CACHE}"
      RESULT_VARIABLE _result
    )
    SET (ENV{LD_LIBRARY_PATH} ${_orig_ldlibpath})
    IF (_result)
      FILE (REMOVE "${_jdk_cachefile}")
      MESSAGE (FATAL_ERROR "Error downloading JDK :( ${_stderr}")
    ENDIF ()
    SET (${var} "${_jdk_cachefile}" PARENT_SCOPE)
  ENDFUNCTION (_DOWNLOAD_JDK)

  FUNCTION (_EXPLODE_JAVA_LINUX jdk_archive explode_dir)
    # Linux is easy
    EXPLODE_ARCHIVE ("${jdk_archive}" "${explode_dir}")
  ENDFUNCTION (_EXPLODE_JAVA_LINUX)

  FUNCTION (_EXPLODE_JAVA_NONLINUX jdk_archive explode_dir)
    IF (WIN32)
      SET (_scriptext bat)
    ELSE ()
      SET (_scriptext sh)
    ENDIF ()
    EXECUTE_PROCESS (
      COMMAND "${CMAKE_CURRENT_LIST_DIR}/unpack-jdk.${_scriptext}"
        "${jdk_archive}" "${explode_dir}"
      RESULT_VARIABLE _result
    )
    IF (_result)
      MESSAGE (FATAL_ERROR "Error unpacking JDK :( ${_stderr}")
    ENDIF ()
  ENDFUNCTION (_EXPLODE_JAVA_NONLINUX)

  FUNCTION (GET_JAVA_VERSION out_java_home)
    # Unlike DOWNLOAD_DEP(), we explode Java downloads into the cache directory,
    # not the binary directory. This means we don't need to re-explode it
    # every time we clean the binary directory. We could do the same for
    # other downloaded deps (and probably should), but we have less control
    # other whether any parts of the build do naughty things like modify the
    # exploded dep contents.
    _DETERMINE_ARCH (_arch)
    SET (_explode_jdkdir "jdk1.${_jdk_major}.0_${_jdk_update}")
    SET (_explode_archdir "${CB_DOWNLOAD_DEPS_CACHE}/exploded/${_arch}")
    SET (_java_home "${_explode_archdir}/${_explode_jdkdir}")
    SET (${out_java_home} "${_java_home}" PARENT_SCOPE)

    # We assume the java binary existing is sufficient to say that the requested
    # java version has been downloaded successfully.
    IF (WIN32)
      SET (_javaexe "${_java_home}/jre/bin/java.exe")
    ELSE ()
      SET (_javaexe "${_java_home}/jre/bin/java")
    ENDIF ()
    IF (EXISTS "${_javaexe}")
      MESSAGE (STATUS "Using downloaded Oracle JDK at ${_java_home}")
      RETURN ()
    ENDIF ()

    # Otherwise, need to download and explode
    SET (_jdk_ver "${_jdk_major}u${_jdk_update}")
    _DOWNLOAD_JDK (${_jdk_ver} _jdk_archive)
    MESSAGE (STATUS "Extracting JDK ${_jdk_ver}...")
    IF (_platform_head STREQUAL "window" OR _platform STREQUAL "macosx")
      _EXPLODE_JAVA_NONLINUX ("${_jdk_archive}" "${_java_home}")
    ELSE ()
      # Presumed Linux
      _EXPLODE_JAVA_LINUX ("${_jdk_archive}" "${_explode_archdir}")
    ENDIF ()

    # Error-check
    IF (NOT EXISTS "${_javaexe}")
      MESSAGE (FATAL_ERROR "Downloaded JDK, but no ${_javaexe} found!")
    ENDIF ()

    MESSAGE (STATUS "Using downloaded Oracle JDK at ${_java_home}")

  ENDFUNCTION (GET_JAVA_VERSION)

  # For production builds - or by user request - we will download a specific
  # Oracle JDK for use in the build
  IF (CB_PRODUCTION_BUILD OR CB_DOWNLOAD_JAVA)
    GET_JAVA_VERSION (java_home)
    SET (JAVA_HOME "${java_home}")
  ENDIF ()

  # Delegate to CMake's own FindJava
  FIND_PACKAGE (Java REQUIRED COMPONENTS Development)

  # Error-check - for production builds, ensure we actually found the
  # declared version
  IF (CB_PRODUCTION_BUILD)
    SET (_expected_jdkver "1.${_jdk_major}.0.${_jdk_update}")
    IF (NOT ${Java_VERSION} STREQUAL ${_expected_jdkver})
      MESSAGE (FATAL_ERROR "Did not find required JDK version ${_expected_jdkver} in production build!")
    ENDIF ()
  ENDIF ()


  SET (FindCouchbaseJava_INCLUDED 1 PARENT_SCOPE)
ENDIF (NOT FindCouchbaseJava_INCLUDED)
