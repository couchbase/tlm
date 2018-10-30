include(ExternalProject)

ExternalProject_Add(double-conversion
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D CMAKE_INSTALL_LIBDIR=lib
             -D BUILD_SHARED_LIBS=OFF
             -D BUILD_TESTING=OFF
	     -D CMAKE_BUILD_TYPE=RelWithDebInfo

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/cmake
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
