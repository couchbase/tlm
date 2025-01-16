include(ExternalProject)

ExternalProject_Add(benchmark
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}

    CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
               -D CMAKE_BUILD_TYPE=RelWithDebInfo
               -D CMAKE_INSTALL_LIBDIR=lib
               -D CMAKE_CXX_STANDARD_REQUIRED=ON
               -D BUILD_SHARED_LIBS=OFF
               -D BENCHMARK_ENABLE_TESTING=OFF
               -D BENCHMARK_ENABLE_GTEST_TESTS=OFF
               -D BENCHMARK_ENABLE_INSTALL=ON
               -D BENCHMARK_DOWNLOAD_DEPENDENCIES=OFF

    CMAKE_CACHE_ARGS ${common_cmake_cache_args}

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
            COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/pkgconfig)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
