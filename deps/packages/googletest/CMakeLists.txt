include(ExternalProject)
list(APPEND cache_args ${common_cmake_cache_args})
list(APPEND cache_args -DCMAKE_CXX_VISIBILITY_PRESET:STRING=hidden)
list(APPEND cache_args -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON)

ExternalProject_Add(googletest
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG v${_git_rev}

    CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
               -D CMAKE_BUILD_TYPE=RelWithDebInfo
               -D CMAKE_INSTALL_LIBDIR=lib
               -D CMAKE_CXX_STANDARD_REQUIRED=ON
               -D BUILD_SHARED_LIBS=OFF
               -D gtest_force_shared_crt=ON

    CMAKE_CACHE_ARGS ${cache_args}

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
            COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/pkgconfig)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
