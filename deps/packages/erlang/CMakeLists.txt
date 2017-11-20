# Downloads the declared version of Erlang source code and builds it.

INCLUDE (ExternalProject)

IF (WIN32)
  SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/erlang_windows.bat)
ELSE ()
  SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/erlang_unix.sh)
ENDIF ()
SET (_install_dir "${CMAKE_BINARY_DIR}/install")
FILE (TO_NATIVE_PATH "${_install_dir}" _install_dir)

ExternalProject_Add (erlang
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E make_directory <INSTALL_DIR>
  BUILD_COMMAND "${_build_script}" <INSTALL_DIR> ${PLATFORM}
  BUILD_IN_SOURCE 1
  INSTALL_DIR "${_install_dir}"
  INSTALL_COMMAND "${CMAKE_COMMAND}" -E copy
    "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt"
    <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
