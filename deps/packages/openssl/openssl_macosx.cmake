# Downloads the declared version of OpenSSL source code and builds it.

include(ExternalProject)

### Download, configure and build OpenSSL #################################
ExternalProject_Add(openssl
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install

  BUILD_IN_SOURCE 1

  CONFIGURE_COMMAND ./Configure darwin64-x86_64-cc
                                shared
                                enable-ec_nistp_64_gcc_128
                                no-comp
                                no-ssl2
                                no-ssl3
                                --openssldir=<INSTALL_DIR>
                    WORKING_DIRECTORY <SOURCE_DIR>

  BUILD_COMMAND make depend
      COMMAND make -j4
      WORKING_DIRECTORY <SOURCE_DIR>

  INSTALL_COMMAND make install
      COMMAND rm <INSTALL_DIR>/lib/libcrypto.a <INSTALL_DIR>/lib/libssl.a
      COMMAND chmod u+w <INSTALL_DIR>/lib/libssl.1.0.0.dylib <INSTALL_DIR>/lib/libcrypto.1.0.0.dylib <INSTALL_DIR>/bin/openssl
      COMMAND install_name_tool -id @rpath/libssl.1.0.0.dylib <INSTALL_DIR>/lib/libssl.1.0.0.dylib
      COMMAND install_name_tool -change <INSTALL_DIR>/lib/libcrypto.1.0.0.dylib @loader_path/libcrypto.1.0.0.dylib <INSTALL_DIR>/lib/libssl.1.0.0.dylib
      COMMAND install_name_tool -id @rpath/libcrypto.1.0.0.dylib <INSTALL_DIR>/lib/libcrypto.1.0.0.dylib
      COMMAND install_name_tool -change <INSTALL_DIR>/lib/libssl.1.0.0.dylib @executable_path/../lib/libssl.1.0.0.dylib
                                -change <INSTALL_DIR>/lib/libcrypto.1.0.0.dylib @executable_path/../lib/libcrypto.1.0.0.dylib <INSTALL_DIR>/bin/openssl
      COMMAND chmod u-w <INSTALL_DIR>/lib/libssl.1.0.0.dylib <INSTALL_DIR>/lib/libcrypto.1.0.0.dylib <INSTALL_DIR>/bin/openssl
      COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY bin lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
      WORKING_DIRECTORY <SOURCE_DIR>
)
