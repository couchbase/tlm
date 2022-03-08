# Downloads the declared version of icu4c source code and builds it.

include(ExternalProject)

# For APPLE we anyway set rpaths using install_name_tool below

# Apply mac patch for ICU-20526 "fix pkgdata where LD_SONAME has a trailing space"
# https://github.com/unicode-org/icu/commit/1c553b9cf28d25c0aaf961c5f587f4ad3cee2679
# https://github.com/unicode-org/icu/commit/83a0542b5b52a30b7af736f5ef6b0405f6582867

if (APPLE)
    SET(_rpath_options "")
    SET(_rpath-link_options "")
    SET(patch_command PATCH_COMMAND patch -p1 < ${CMAKE_CURRENT_SOURCE_DIR}/icu4c_mac.patch)
else (APPLE)
    SET(_rpath_options "--enable-rpath")
    SET(_rpath-link_options "--enable-rpath-link")
    unset(patch_command)
endif (APPLE)
### Download, configure and build icu4c ####################################
_DETERMINE_CPU_COUNT(_parallelism)
ExternalProject_Add(icu4c
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  ${patch_command}

  CONFIGURE_COMMAND sudo "${CMAKE_CURRENT_SOURCE_DIR}/check_xlocale_h.sh"
  COMMAND <SOURCE_DIR>/source/configure LDFLAGS=${ICU_LDFLAGS}
                                                  --prefix=<INSTALL_DIR>
                                                  --disable-extras
                                                  --disable-layout
                                                  --disable-tests
                                                  --disable-samples
                                                  ${_rpath_options}
                                                  ${_rpath-link_options}
  BUILD_COMMAND $(MAKE) -j${_parallelism} all

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
    COMMAND install_name_tool -id @rpath/libicudata.59.1.dylib lib/libicudata.59.1.dylib
    COMMAND install_name_tool -id @rpath/libicui18n.59.1.dylib
                              -change libicuuc.59.dylib @loader_path/libicuuc.59.dylib
                              -change libicudata.59.dylib @loader_path/libicudata.59.dylib
                              lib/libicui18n.59.1.dylib
    COMMAND install_name_tool -id @rpath/libicuio.59.1.dylib
                              -change libicuuc.59.dylib @loader_path/libicuuc.59.dylib
                              -change ../lib/libicudata.59.1.dylib @loader_path/libicudata.59.1.dylib
                              -change libicui18n.59.dylib @loader_path/ibicui18n.59.dylib
                              lib/libicuio.59.1.dylib
    COMMAND install_name_tool -id @rpath/libicutu.59.1.dylib
                              -change libicui18n.59.dylib @loader_path/libicui18n.59.dylib
                              -change libicuuc.59.dylib @loader_path/libicuuc.59.dylib
                              -change libicudata.59.dylib @loader_path/libicudata.59.dylib
                              lib/libicutu.59.1.dylib
    COMMAND install_name_tool -id @rpath/libicuuc.59.1.dylib
                              -change libicudata.59.dylib @loader_path/libicudata.59.dylib
                              lib/libicuuc.59.1.dylib
    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)
