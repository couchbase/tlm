# Downloads the declared version of flatbuffers source code and builds it.

include(ExternalProject)

### Download, configure and build flatbuffers ####################################
ExternalProject_Add(flatbuffers
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install -D FLATBUFFERS_BUILD_TESTS=OFF -DCMAKE_CXX_FLAGS=-Wno-error=implicit-fallthrough
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND ${CMAKE_COMMAND} -E echo "" > <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
