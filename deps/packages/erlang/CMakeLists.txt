# Downloads the declared version of Erlang source code and builds it.

include(ExternalProject)

### Download, configure and build erlang ####################################

SET(ERL_CFLAGS "-fno-strict-aliasing -O3 -ggdb3 -DOPENSSL_NO_EC=1")

ExternalProject_Add(erlang
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND ./otp_build autoconf
            COMMAND touch <SOURCE_DIR>/lib/debugger/SKIP
                          <SOURCE_DIR>/lib/megaco/SKIP
                          <SOURCE_DIR>/lib/observer/SKIP
                          <SOURCE_DIR>/lib/wx/SKIP
            COMMAND <SOURCE_DIR>/configure --prefix=<INSTALL_DIR>
                                           --enable-smp-support
                                           --disable-hipe
                                           --disable-fp-exceptions
                                           CFLAGS=${ERL_CFLAGS}

  BUILD_IN_SOURCE 1
  BUILD_COMMAND $(MAKE) -j8

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND ${CMAKE_COMMAND} -E echo "FILE(COPY bin lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
  # Invoke Erlang 'Install' to update the Erlang ROOTDIR
          COMMAND ${CMAKE_COMMAND} -E echo "EXECUTE_PROCESS(COMMAND \${CMAKE_INSTALL_PREFIX}/lib/erlang/Install -minimal \${CMAKE_INSTALL_PREFIX}/lib/erlang)" >> <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
