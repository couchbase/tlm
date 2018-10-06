# Downloads the declared version of libsnappy source code and builds it.

include(ExternalProject)

### Download, configure and build snappy ####################################
ExternalProject_Add(snappy
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=<INSTALL_DIR>
                                           --enable-shared
                                           --disable-static
                                           --disable-dependency-tracking
                                           --disable-gtest

  BUILD_COMMAND $(MAKE) all

  INSTALL_DIR ${CMAKE_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND rm -rf <INSTALL_DIR>/share
          COMMAND rm -f <INSTALL_DIR>/lib/libsnappy.la

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib include DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(snappy install_name
    COMMAND install_name_tool -id @rpath/libsnappy.1.dylib <BINARY_DIR>/.libs/libsnappy.1.dylib
    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
