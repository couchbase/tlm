# Downloads the declared version of v8 source code and builds it.

include(ExternalProject)

if (APPLE)
   SET(V8_LIBRARY_FILE "<SOURCE_DIR>/out/x64.release/libv8.dylib")
   SET(V8_PLATFORM_FILE "<SOURCE_DIR>/out/x64.release/libv8_libplatform.a")
   SET(GYP_FLAGS "-Dcomponent=shared_library -Dv8_enable_backtrace=1 -Dv8_use_snapshot='false' -Dv8_use_external_startup_data=0 -Dv8_enable_i18n_support=1")
else (APPLE)
   SET(V8_LIBRARY_FILE "<SOURCE_DIR>/out/x64.release/lib.target/libv8.so")
   SET(V8_PLATFORM_FILE "<SOURCE_DIR>/out/x64.release/obj.target/tools/gyp/libv8_libplatform.a")
   SET(GYP_FLAGS "-Dcomponent=shared_library -Dv8_enable_backtrace=1 -Dv8_use_snapshot='false' -Dclang=0 -Dv8_use_external_startup_data=0 -Dv8_enable_i18n_support=1")
endif (APPLE)

### Download, configure and build v8 ####################################
ExternalProject_Add(v8
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  BUILD_IN_SOURCE 1

  CONFIGURE_COMMAND cd <SOURCE_DIR>/build
  COMMAND pip install --user argparse

  BUILD_COMMAND $(MAKE) -j4 x64.release GYPFLAGS+=${GYP_FLAGS}

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install

  INSTALL_COMMAND mkdir -p <INSTALL_DIR>/lib <INSTALL_DIR>/archive <INSTALL_DIR>/include
  COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_FILE} <INSTALL_DIR>/lib
  COMMAND ${CMAKE_COMMAND} -E copy ${V8_PLATFORM_FILE} <INSTALL_DIR>/archive
  COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include <INSTALL_DIR>/include
  COMMAND ${CMAKE_COMMAND} -E remove -f <INSTALL_DIR>/include/OWNERS

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
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
