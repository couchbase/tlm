# Downloads the declared version of libjemalloc source code and builds it.

include(ExternalProject)

if (${CMAKE_SYSTEM_NAME} STREQUAL "SunOS")
  set(EXTRA_CONFIGURE_OPTIONS "--disable-tls")
endif(${CMAKE_SYSTEM_NAME} STREQUAL "SunOS")

### Download, configure and build jemalloc ####################################
ExternalProject_Add(jemalloc
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND autoconf <SOURCE_DIR>/configure.ac > <SOURCE_DIR>/configure
                    COMMAND chmod u+x <SOURCE_DIR>/configure
                    COMMAND CPPFLAGS=-I/usr/local/include <SOURCE_DIR>/configure
                                                    --prefix=<INSTALL_DIR>
                                                    --with-jemalloc-prefix=je_
                                                    --disable-cache-oblivious
                                                    --disable-zone-allocator
                                                    --enable-prof
                                                    ${EXTRA_CONFIGURE_OPTIONS}

  BUILD_COMMAND $(MAKE) build_lib_shared

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install_lib_shared install_include install_bin

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY bin/jeprof DESTINATION \"\${CMAKE_INSTALL_PREFIX}/bin\")" >> <INSTALL_DIR>/CMakeLists.txt
)

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(jemalloc install_name
    COMMAND install_name_tool -id @rpath/libjemalloc.2.dylib lib/libjemalloc.2.dylib

    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
