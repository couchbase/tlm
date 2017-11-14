# Downloads the declared version of LZ4 and builds it.

include(ExternalProject)

### Download, configure and build lz4  ####################################
ExternalProject_Add(lz4
  GIT_REPOSITORY https://github.com/couchbasedeps/lz4
  GIT_TAG ${_git_rev}
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  CONFIGURE_COMMAND cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> -DCMAKE_MACOSX_RPATH=1 -DCMAKE_INSTALL_LIBDIR=lib <SOURCE_DIR>/contrib/cmake_unofficial
  BUILD_COMMAND cmake --build <BINARY_DIR>
  INSTALL_COMMAND cmake --build <BINARY_DIR> --target install
)

ExternalProject_Add_Step(lz4 create_install_cmakelist
  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
  DEPENDEES build
  DEPENDERS install
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
