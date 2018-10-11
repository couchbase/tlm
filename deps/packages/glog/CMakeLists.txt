include(ExternalProject)

ExternalProject_Add(glog
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  BUILD_IN_SOURCE 1
  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D CMAKE_BUILD_TYPE=RelWithDebInfo
             -D BUILD_SHARED_LIBS=OFF

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/cmake
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
