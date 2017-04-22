# Downloads the declared version of OpenSSL source code and builds it.

include(ExternalProject)

IF ($ENV{target_arch} STREQUAL "x86")
  SET (OPENSSL_MACHINE x86)
ELSE ()
  SET (OPENSSL_MACHINE x64)
ENDIF ()

### Download, configure and build OpenSSL #################################
ExternalProject_Add(openssl
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND ""

  BUILD_COMMAND cd <SOURCE_DIR>
        COMMAND perl Configure VC-WIN64A --prefix=./build
        COMMAND ms\\do_win64a.bat
        COMMAND nmake -f ms\\ntdll.mak
        COMMAND nmake -f ms\\ntdll.mak install

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory "<SOURCE_DIR>/build" <INSTALL_DIR>
          COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY bin include lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

