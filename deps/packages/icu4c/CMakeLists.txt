# Downloads the declared version of icu4c source code and builds it.

include(ExternalProject)

### Download, configure and build icu4c ####################################
ExternalProject_Add(icu4c
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

# For APPLE we anyway set rpaths using install_name_tool below
 if(not APPLE)
   SET(_extra_configure_options "--enable-rpath")
 endif()
 CONFIGURE_COMMAND <SOURCE_DIR>/source/configure LDFLAGS=${ICU_LDFLAGS}
                                                  --prefix=<INSTALL_DIR>
                                                  --disable-extras
                                                  --disable-layout
                                                  --disable-tests
                                                  --disable-samples
                                                   ${_extra_configure_options}
  BUILD_COMMAND $(MAKE) -j4 all

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/bin
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/sbin
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/share

  COMMAND ${CMAKE_COMMAND} -E echo "FILE(COPY lib DESTINATION \${CMAKE_INSTALL_PREFIX})" >> <INSTALL_DIR>/CMakeLists.txt
)

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(icu4c install_name
    # Fixup all libraries
    COMMAND install_name_tool -id @rpath/libicudata.54.1.dylib lib/libicudata.54.1.dylib
    COMMAND install_name_tool -id @rpath/libicui18n.54.1.dylib
                              -change libicuuc.54.dylib @loader_path/libicuuc.54.dylib
                              -change libicudata.54.dylib @loader_path/libicudata.54.dylib
                              lib/libicui18n.54.1.dylib
    COMMAND install_name_tool -id @rpath/libicuio.54.1.dylib
                              -change libicuuc.54.dylib @loader_path/libicuuc.54.dylib
                              -change ../lib/libicudata.54.1.dylib @loader_path/libicudata.54.1.dylib
                              -change libicui18n.54.dylib @loader_path/ibicui18n.54.dylib
                              lib/libicuio.54.1.dylib
    COMMAND install_name_tool -id @rpath/libicutu.54.1.dylib
                              -change libicui18n.54.dylib @loader_path/libicui18n.54.dylib
                              -change libicuuc.54.dylib @loader_path/libicuuc.54.dylib
                              -change libicudata.54.dylib @loader_path/libicudata.54.dylib
                              lib/libicutu.54.1.dylib
    COMMAND install_name_tool -id @rpath/libicuuc.54.1.dylib
                              -change libicudata.54.dylib @loader_path/libicudata.54.dylib
                              lib/libicuuc.54.1.dylib
    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
