# Downloads the declared version of libuv source code and builds it.

include(ExternalProject)

IF (WIN32)
  SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/libuv_windows.bat)
ELSE ()
  SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/libuv_unix.sh)
ENDIF ()

SET (_install_dir "${CMAKE_BINARY_DIR}/install")
FILE (TO_NATIVE_PATH "${_install_dir}" _install_dir)

### Download, configure and build libuv ####################################
ExternalProject_Add(libuv
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND ${CMAKE_COMMAND} -E echo do be do be
  BUILD_COMMAND ${CMAKE_COMMAND} -E echo dooooo
  BUILD_IN_SOURCE 1
  INSTALL_DIR "${_install_dir}"
  INSTALL_COMMAND ${_build_script} <INSTALL_DIR>

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib include DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
