# Downloads the declared version of libevent source code and builds it.

include(ExternalProject)

### Download, configure and build libevent ####################################
ExternalProject_Add(libevent
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  UPDATE_COMMAND  <SOURCE_DIR>/autogen.sh
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=<INSTALL_DIR>
                                           --enable-thread-support
                                           --disable-dependency-tracking
                                           --disable-openssl
                                           --disable-debug-mode
                                           --disable-libevent-regress
                                           --enable-shared
                                           --disable-static

  BUILD_COMMAND $(MAKE) all

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND rm -rf <INSTALL_DIR>/bin/event_rpcgen.py
          COMMAND rm -rf <INSTALL_DIR>/lib/pkgconfig
          COMMAND rm -f <INSTALL_DIR>/lib/libevent.la
          COMMAND rm -f <INSTALL_DIR>/lib/libevent_core.la
          COMMAND rm -f <INSTALL_DIR>/lib/libevent_extra.la
          COMMAND rm -f <INSTALL_DIR>/lib/libevent_pthreads.la

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(libevent install_name
    COMMAND install_name_tool -id @rpath/libevent-2.0.5.dylib <BINARY_DIR>/.libs/libevent-2.0.5.dylib
    COMMAND install_name_tool -id @rpath/libevent_core-2.0.5.dylib <BINARY_DIR>/.libs/libevent_core-2.0.5.dylib
    COMMAND install_name_tool -id @rpath/libevent_extra-2.0.5.dylib <BINARY_DIR>/.libs/libevent_extra-2.0.5.dylib
    COMMAND install_name_tool -id @rpath/libevent_pthreads-2.0.5.dylib <BINARY_DIR>/.libs/libevent_pthreads-2.0.5.dylib
    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
