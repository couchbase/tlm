include(ExternalProject)

ExternalProject_Add(googletest
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG release-${_git_rev}

    CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
               -D CMAKE_BUILD_TYPE=RelWithDebInfo
               -D CMAKE_INSTALL_LIBDIR=lib
               -D CMAKE_CXX_STANDARD=17
               -D CMAKE_CXX_STANDARD_REQUIRED=ON
               -D BUILD_SHARED_LIBS=OFF
               -D gtest_force_shared_crt=ON

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
            COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/pkgconfig)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
