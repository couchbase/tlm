# "Builds" icu4c for Windows (actually repackages binary)

include(ExternalProject)

SET (_install_dir "${CMAKE_BINARY_DIR}/install")
FILE (TO_NATIVE_PATH "${_install_dir}" _install_dir)

SET (_build_script "${CMAKE_CURRENT_SOURCE_DIR}/icu4c_windows.bat")
### Download, configure and build icu4c ####################################
ExternalProject_Add(icu4c
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND ${CMAKE_COMMAND} -E echo do be do be
  BUILD_COMMAND ${CMAKE_COMMAND} -E echo dooooo
  BUILD_IN_SOURCE 1
  INSTALL_DIR "${_install_dir}"
  INSTALL_COMMAND ${_build_script} <INSTALL_DIR>

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY bin lib include DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)
