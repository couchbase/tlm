# Downloads the declared version of libcurl source code and builds it.

include(ExternalProject)

### Download, configure and build curl ####################################
ExternalProject_Add(curl
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  UPDATE_COMMAND autoreconf -i
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=<INSTALL_DIR>
                                           --disable-debug
                                           --enable-optimize
                                           --disable-warnings
                                           --disable-werror
                                           --disable-curldebug
                                           --enable-shared
                                           --disable-static
                                           --without-libssh2

  BUILD_COMMAND $(MAKE) all

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND rm -rf <INSTALL_DIR>/bin/curl-config
          COMMAND rm -rf <INSTALL_DIR>/lib/pkgconfig
          COMMAND rm -rf <INSTALL_DIR>/share
          COMMAND rm -f <INSTALL_DIR>/lib/libcurl.la

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY bin lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(curl install_name
    COMMAND install_name_tool -id @rpath/libcurl.4.dylib <BINARY_DIR>/lib/.libs/libcurl.4.dylib
    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

