# Downloads the declared version of grpc source code and builds it.

include(ExternalProject)

# Expand grpc's deps to a separate install directory so we don't end up
# packaging them up in the grpc cbdep itself.
set(_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
set(_deps_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
set(CMAKE_INSTALL_PREFIX "${_deps_install}")

# Install grpc's prereqs that we already provide
DECLARE_DEP (openssl VERSION 1.1.1d-cb1 PLATFORMS amzn2 centos7 debian8 debian9 macosx suse12 suse15 ubuntu16.04 ubuntu18.04 windows_msvc2017)
DECLARE_DEP (zlib V2 VERSION 1.2.11 BUILD 4 PLATFORMS amzn2 centos7 debian8 debian9 macosx suse12 suse15 ubuntu16.04 ubuntu18.04 windows_msvc2017)
DECLARE_DEP (zlib V2 VERSION 1.2.11 BUILD 6 PLATFORMS rhel8 ubuntu20.04)

# Restore the INSTALL_PREFIX
set(CMAKE_INSTALL_PREFIX ${_orig_install_prefix})

### Download, configure and build grpc ##################################
IF (WIN32)
  SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/${_dep_package}_windows.bat)
ELSE ()
  SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/${_dep_package}_unix.sh)
ENDIF ()
SET (_install_dir "${CMAKE_BINARY_DIR}/install")
FILE (TO_NATIVE_PATH "${_install_dir}" _install_dir)

ExternalProject_Add (${_dep_package}
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E make_directory <INSTALL_DIR>
  BUILD_COMMAND "${_build_script}" <INSTALL_DIR> ${PLATFORM} "${_dep_version}" "${CMAKE_CURRENT_BINARY_DIR}"
  BUILD_IN_SOURCE 1
  INSTALL_DIR "${_install_dir}"
  INSTALL_COMMAND ""
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
