# Downloads the declared version of prometheus-cpp source code and builds it.

include(ExternalProject)

SET (_install_dir "${CMAKE_BINARY_DIR}/install")

# Expand prometheus-cpp deps to a separate install directory so we don't end up
# packaging them up in the cbdep itself.
set(_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
set(_deps_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
set(CMAKE_INSTALL_PREFIX "${_deps_install}")

# Install prometheus-cpp prereqs that we already provide
DECLARE_DEP (zlib V2 VERSION 1.2.13 BUILD 2 PLATFORMS linux macosx windows)

# Restore the INSTALL_PREFIX
set(CMAKE_INSTALL_PREFIX ${_orig_install_prefix})

ExternalProject_Add(${_dep_package}
        GIT_REPOSITORY ${_git_repo}
        GIT_TAG ${_git_rev}

        CMAKE_ARGS -DCMAKE_BUILD_TYPE=RelWithDebInfo
            -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
            -DBUILD_SHARED_LIBS=OFF
            -DGENERATE_PKGCONFIG=OFF
            -DENABLE_PUSH=OFF
            -DTHIRDPARTY_CIVETWEB_WITH_SSL=OFF
            -DRUN_IWYU=OFF
            -DENABLE_TESTING=OFF
            -DCMAKE_POSITION_INDEPENDENT_CODE=ON
            -DZLIB_ROOT=${CMAKE_CURRENT_BINARY_DIR}/zlib.exploded

        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        )

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
