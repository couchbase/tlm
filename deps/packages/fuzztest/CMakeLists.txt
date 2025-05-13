include(PlatformIntrospection)
include(ExternalProject)

_DETERMINE_CPU_COUNT(_parallelism)

DECLARE_DEP(googletest VERSION 1.15.2-cb1 PLATFORMS linux macosx windows)
set(GTest_ROOT ${CMAKE_CURRENT_BINARY_DIR}/googletest.exploded)

ExternalProject_Add(fuzztest
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/wrapper
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
        -DCMAKE_BUILD_TYPE=RelWithDebInfo
        -DCMAKE_INSTALL_LIBDIR=lib
        -D_git_repo=${_git_repo}
        -D_git_rev=${_git_rev}
        -DGTest_ROOT=${GTest_ROOT}
    BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}
    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
