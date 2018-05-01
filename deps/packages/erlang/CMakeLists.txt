# Downloads the declared version of Erlang source code and builds it.

# We bundle OpenSSL on some platforms, and we want support
# for OpenSSL in Erlang so we need to install the OpenSSL Package.
# Note: So far this is only for Windows and MacOS. On a couple
# Linux platforms, eg Debian 9, we do need a custom build of OpenSSL
# but *only* for Erlang, therefore we don't have cbdeps packages for
# those platforms; erlang_unix.sh actually builds OpenSSL here.
SET (_openssl_install "${CMAKE_CURRENT_BINARY_DIR}/ignored")
SET (_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
SET (CMAKE_INSTALL_PREFIX "${_openssl_install}")
DECLARE_DEP (openssl VERSION 1.0.2k-cb2 PLATFORMS macosx)
SET (CMAKE_INSTALL_PREFIX "${_orig_install_prefix}")

INCLUDE (ExternalProject)

IF (WIN32)
  SET (_build_scriptdir ${CMAKE_CURRENT_SOURCE_DIR}/windows)
  SET (_build_script ${_build_scriptdir}/erlang_windows.bat)
  FILE (TO_NATIVE_PATH "${_build_scriptdir}" _build_scriptdir)
ELSE ()
  SET (_build_scriptdir ${CMAKE_CURRENT_SOURCE_DIR}/unix)
  SET (_build_script ${_build_scriptdir}/erlang_unix.sh)
ENDIF ()
SET (_install_dir "${CMAKE_BINARY_DIR}/install")
FILE (TO_NATIVE_PATH "${_install_dir}" _install_dir)

ExternalProject_Add (erlang
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E make_directory <INSTALL_DIR>
  BUILD_COMMAND "${_build_script}" <INSTALL_DIR> ${_build_scriptdir} ${PLATFORM}
      "${CMAKE_CURRENT_BINARY_DIR}/openssl.exploded"
  BUILD_IN_SOURCE 1
  INSTALL_DIR "${_install_dir}"
  INSTALL_COMMAND ""
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
