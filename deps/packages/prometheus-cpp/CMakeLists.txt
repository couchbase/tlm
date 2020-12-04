# Downloads the declared version of prometheus-cpp source code and builds it.

include(ExternalProject)

SET (_install_dir "${CMAKE_BINARY_DIR}/install")

# Expand prometheus-cpp deps to a separate install directory so we don't end up
# packaging them up in the cbdep itself.
set(_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
set(_deps_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
set(CMAKE_INSTALL_PREFIX "${_deps_install}")

# Install prometheus-cpp prereqs that we already provide
DECLARE_DEP (zlib V2 VERSION 1.2.11 BUILD 4 PLATFORMS amzn2 centos7 debian8 debian9 macosx suse12 suse15 ubuntu16.04 ubuntu18.04 windows_msvc2017)
DECLARE_DEP (zlib V2 VERSION 1.2.11 BUILD 6 PLATFORMS rhel8 ubuntu20.04)

# Restore the INSTALL_PREFIX
set(CMAKE_INSTALL_PREFIX ${_orig_install_prefix})

ExternalProject_Add(${_dep_package}
        GIT_REPOSITORY ${_git_repo}
        GIT_TAG ${_git_rev}

        CMAKE_ARGS -DCMAKE_BUILD_TYPE=RelWithDebInfo
            -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
            -DBUILD_SHARED_LIBS=OFF
            -DENABLE_PUSH=OFF
            -DZLIB_ROOT=${CMAKE_CURRENT_BINARY_DIR}/zlib.exploded
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON

        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        )

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
