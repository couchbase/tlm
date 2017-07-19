# Downloads the declared version of rocksdb and builds it.

include(ExternalProject)

### Download, configure and build rocksdb  ####################################
ExternalProject_Add(rocksdb
  GIT_REPOSITORY https://github.com/facebook/rocksdb.git
  GIT_TAG ${_git_rev}

  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND ""

  BUILD_COMMAND $(MAKE) shared_lib
  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) INSTALL_PATH=<INSTALL_DIR> install-shared

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(rocksdb install_name
    COMMAND install_name_tool -id @rpath/librocksdb.5.6.dylib <BINARY_DIR>/librocksdb.5.6.dylib

    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
