# Downloads the declared version of icu4c source code and builds it.

include(ExternalProject)

### Download, configure and build icu4c ####################################
ExternalProject_Add(icu4c
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND <SOURCE_DIR>/source/configure LDFLAGS=${ICU_LDFLAGS}
                                                  --prefix=<INSTALL_DIR>
                                                  --disable-extras
                                                  --disable-layout
                                                  --disable-tests
                                                  --disable-samples

  BUILD_COMMAND make -j4 all

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND make install
          COMMAND ${CMAKE_COMMAND} -E remove -f <INSTALL_DIR>/bin/derb
                                                <INSTALL_DIR>/bin/genbrk
                                                <INSTALL_DIR>/bin/gencfu
                                                <INSTALL_DIR>/bin/gencnval
                                                <INSTALL_DIR>/bin/genctd
                                                <INSTALL_DIR>/bin/genrb
                                                <INSTALL_DIR>/bin/icuinfo
                                                <INSTALL_DIR>/bin/makeconv
                                                <INSTALL_DIR>/bin/pkgdata
                                                <INSTALL_DIR>/bin/uconv
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/sbin
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/share

  # Need to configure icu-config to use the prefix it's been installed into.
  COMMAND ${CMAKE_COMMAND} -E echo "FILE(MAKE_DIRECTORY \${CMAKE_INSTALL_PREFIX}/bin)" > <INSTALL_DIR>/CMakeLists.txt
  COMMAND ${CMAKE_COMMAND} -E echo "CONFIGURE_FILE(bin/icu-config \${CMAKE_INSTALL_PREFIX}/bin @ONLY)" >> <INSTALL_DIR>/CMakeLists.txt
  COMMAND ${CMAKE_COMMAND} -E echo "FILE(COPY include lib DESTINATION \${CMAKE_INSTALL_PREFIX})" >> <INSTALL_DIR>/CMakeLists.txt
)

# Modify icu-config to replace the hardcoded prefix with a variable, which
# will be expanded at cbdeps install time.
ExternalProject_Add_Step(icu4c change_icu_config_prefix
  COMMAND sed -i -E "s/^default_prefix=.*/default_prefix=\"\\\@CMAKE_INSTALL_PREFIX\\\@\"/"
          config/icu-config
  DEPENDEES build
  DEPENDERS install
  WORKING_DIRECTORY <BINARY_DIR>
)

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(icu4c install_name
    # Fixup all libraries
    COMMAND install_name_tool -id @rpath/libicudata.44.0.dylib lib/libicudata.44.0.dylib
    COMMAND install_name_tool -id @rpath/libicui18n.44.0.dylib
                              -change libicuuc.44.dylib @loader_path/libicuuc.44.dylib
                              -change libicudata.44.dylib @loader_path/libicudata.44.dylib
                              lib/libicui18n.44.0.dylib
    COMMAND install_name_tool -id @rpath/libicuio.44.0.dylib
                              -change libicuuc.44.dylib @loader_path/libicuuc.44.dylib
                              -change ../lib/libicudata.44.0.dylib @loader_path/libicudata.44.0.dylib
                              -change libicui18n.44.dylib @loader_path/ibicui18n.44.dylib
                              lib/libicuio.44.0.dylib
    COMMAND install_name_tool -id @rpath/libicutu.44.0.dylib
                              -change libicui18n.44.dylib @loader_path/libicui18n.44.dylib
                              -change libicuuc.44.dylib @loader_path/libicuuc.44.dylib
                              -change libicudata.44.dylib @loader_path/libicudata.44.dylib
                              lib/libicutu.44.0.dylib
    COMMAND install_name_tool -id @rpath/libicuuc.44.0.dylib
                              -change libicudata.44.dylib @loader_path/libicudata.44.dylib
                              lib/libicuuc.44.0.dylib
    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
