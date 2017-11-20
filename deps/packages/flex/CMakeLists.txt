# Downloads the declared version of flex source code and builds it.

include(ExternalProject)

### Download, configure and build flex ##################################
IF (WIN32)
  SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/${_dep_package}_windows.bat)
ELSE ()
  SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/${_dep_package}_unix.sh)
ENDIF ()
SET (_install_dir "${CMAKE_BINARY_DIR}/install")
FILE (TO_NATIVE_PATH "${_install_dir}" _install_dir)

ExternalProject_Add (${_dep_package}
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E make_directory <INSTALL_DIR>
  BUILD_COMMAND "${_build_script}" <INSTALL_DIR> ${PLATFORM} "${_dep_version}"
  BUILD_IN_SOURCE 1
  INSTALL_DIR "${_install_dir}"
  INSTALL_COMMAND "${CMAKE_COMMAND}" -E copy
    "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt"
    <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
