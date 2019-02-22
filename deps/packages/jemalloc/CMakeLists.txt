# Downloads the declared version of libjemalloc source code and builds it.

include(ExternalProject)

### Download, configure and build jemalloc ####################################
IF (WIN32)
  SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/${_dep_package}_windows.bat)
ELSE ()
  SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/${_dep_package}_unix.sh)
ENDIF ()
SET (_install_dir "${CMAKE_BINARY_DIR}/install")

ExternalProject_Add(${_dep_package}
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E make_directory <INSTALL_DIR>
  BUILD_COMMAND "${_build_script}" <INSTALL_DIR>

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND "${CMAKE_COMMAND}" -E copy
    "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt"
    <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
