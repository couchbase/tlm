include(ExternalProject)

_DETERMINE_CPU_COUNT(_parallelism)

ExternalProject_Add(simdutf
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG v${_git_rev}

    CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
               -D CMAKE_BUILD_TYPE=RelWithDebInfo
               -D CMAKE_INSTALL_LIBDIR=lib
               -D CMAKE_CXX_STANDARD=17
               -D SIMDUTF_BENCHMARKS=OFF
               -D SIMDUTF_TESTS=ON
               -D SIMDUTF_ICONV=OFF
               -D SIMDUTF_TOOLS=OFF

    BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}

    TEST_BEFORE_INSTALL 1

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
            COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/pkgconfig)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
