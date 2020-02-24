include(ExternalProject)

ExternalProject_Add(gflags
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D CMAKE_BUILD_TYPE=RelWithDebInfo
             -D CMAKE_POSITION_INDEPENDENT_CODE=ON
             -D BUILD_SHARED_LIBS=OFF
             -D INSTALL_HEADERS=ON

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
