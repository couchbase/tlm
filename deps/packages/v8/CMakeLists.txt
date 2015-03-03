# Downloads the declared version of v8 source code and builds it.

include(ExternalProject)

if (APPLE)
   SET(V8_LIBRARY_FILE "<SOURCE_DIR>/out/x64.release/libv8.dylib")
else (APPLE)
   SET(V8_LIBRARY_FILE "<SOURCE_DIR>/out/x64.release/lib.target/libv8.so")
endif (APPLE)

### Download, configure and build v8 ####################################
ExternalProject_Add(v8
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  BUILD_IN_SOURCE 1

  CONFIGURE_COMMAND cd <SOURCE_DIR>/build && git clone git://github.com/couchbasedeps/gyp -b couchbase-v8-3.21.17
            COMMAND cd <SOURCE_DIR> && git clone git://github.com/couchbasedeps/icu46 third_party/icu && cd third_party/icu && git checkout 73170776491a3e38f68ab0367f3121256a3cc289
  BUILD_COMMAND $(MAKE) -j 8 library=shared x64

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install

  INSTALL_COMMAND mkdir -p <INSTALL_DIR>/lib <INSTALL_DIR>/include
          COMMAND cp ${V8_LIBRARY_FILE} <INSTALL_DIR>/lib
          COMMAND cp <SOURCE_DIR>/include/v8-debug.h <INSTALL_DIR>/include
          COMMAND cp <SOURCE_DIR>/include/v8-preparser.h <INSTALL_DIR>/include
          COMMAND cp <SOURCE_DIR>/include/v8-profiler.h <INSTALL_DIR>/include
          COMMAND cp <SOURCE_DIR>/include/v8-testing.h <INSTALL_DIR>/include
          COMMAND cp <SOURCE_DIR>/include/v8.h <INSTALL_DIR>/include
          COMMAND cp <SOURCE_DIR>/include/v8config.h <INSTALL_DIR>/include
          COMMAND cp <SOURCE_DIR>/include/v8stdint.h <INSTALL_DIR>/include
          COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib include DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib include DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(v8 install_name
    COMMAND install_name_tool -id @rpath/libv8.dylib out/x64.release/libv8.dylib
    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
