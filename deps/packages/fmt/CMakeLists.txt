include(ExternalProject)

_DETERMINE_CPU_COUNT(_parallelism)

ExternalProject_Add(fmt
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
	     -D CMAKE_BUILD_TYPE=RelWithDebInfo

  BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}

  TEST_BEFORE_INSTALL 1

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
