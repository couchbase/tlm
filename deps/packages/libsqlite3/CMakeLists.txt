# Downloads the declared version of liblibsqlite3 source code and builds it.

include(ExternalProject)

# Use OS-provided libsqlite3 on MacOS.
IF (APPLE)
  ADD_CUSTOM_TARGET (libsqlite3
    COMMAND "${CMAKE_COMMAND}" -E echo "Skipping packaging - use MacOS-provided libsqlite"
    )
ELSE (APPLE)

  ### Download, configure and build libsqlite3 ####################################
  ExternalProject_Add(libsqlite3
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}

    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=<INSTALL_DIR>

    BUILD_COMMAND make

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    INSTALL_COMMAND make install

    COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY bin lib include DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
    )

  # OS X-only: Custom post-build step to set the shared library install name.
  if (APPLE)
    ExternalProject_Add_Step(libsqlite3 install_name
      COMMAND install_name_tool -id @rpath/liblibsqlite3.2.dylib lib/liblibsqlite3.2.dylib

      DEPENDEES build
      DEPENDERS install
      WORKING_DIRECTORY <BINARY_DIR>
      )
  endif(APPLE)

  # cbdeps boilerplate
  _ADD_PACKAGE_STEP()

ENDIF (APPLE)
