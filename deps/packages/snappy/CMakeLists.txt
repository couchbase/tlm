# Downloads the declared version of libsnappy source code and builds it.

include(ExternalProject)

### Download, configure and build snappy ####################################
ExternalProject_Add(snappy
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install -D CMAKE_BUILD_TYPE=Release
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
