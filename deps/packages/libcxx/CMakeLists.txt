# Downloads the declared version of libcxx and libcxxabi source code and builds it.
# As a bit of a cheat, we assume we can check out the same branch of libcxxabi as
# is specified for libcxx (so don't specify a particular commit SHA).

# Note: These steps are pretty hard-coded to values for Ubuntu.

include(ExternalProject)

# Final output directory
SET (INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/install")


### Download, configure and build libcxxabi ####################################
ExternalProject_Add(libcxxabi
  GIT_REPOSITORY https://github.com/couchbasedeps/libcxxabi.git
  GIT_TAG ${_git_rev}

  PREFIX libcxxabi

  # "Update" command - libcxxabi depends on the libcxx source code
  # (includes), but we can't just build libcxx first because it
  # depends on libcxxabi.so. So, we download libcxx again.
  UPDATE_COMMAND echo ${CMAKE_CURRENT_BINARY_DIR}
    COMMAND git clone https://github.com/couchbasedeps/libcxx
    ${CMAKE_CURRENT_BINARY_DIR}/libcxx-copy --single-branch -b ${_git_rev}

  # Configure step
  CMAKE_ARGS -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
    -DLIBCXXABI_LIBCXX_INCLUDES=${CMAKE_CURRENT_BINARY_DIR}/libcxx-copy/include
    -DLIBCXXABI_ENABLE_STATIC=OFF

  BUILD_COMMAND $(MAKE) -j4

  # We install both the lib and include files - libcxxapi by itself
  # only installs the lib, but since libcxx needs the include too
  # it makes sense to install both.
  INSTALL_DIR ${INSTALL_DIR}
  INSTALL_COMMAND $(MAKE) install
    COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include <INSTALL_DIR>/include
)

### Download, configure and build libcxx ####################################
ExternalProject_Add(libcxx
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  DEPENDS libcxxabi

  PREFIX libcxx

  # Configure step
  CMAKE_ARGS -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
    -DLIBCXX_CXX_ABI=libcxxabi
    -DLIBCXX_CXX_ABI_INCLUDE_PATHS=${INSTALL_DIR}/include
    -DLIBCXX_CXX_ABI_LIBRARY_PATH=${INSTALL_DIR}/lib

  BUILD_COMMAND $(MAKE) -j4

  INSTALL_DIR ${INSTALL_DIR}
  INSTALL_COMMAND $(MAKE) install
    COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
