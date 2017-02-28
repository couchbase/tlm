# Downloads the declared version of python-snappy source code and builds it.

# First, download the dependency: snappy itself. Set CMAKE_INSTALL_PREFIX
# to a local directory to dump in there, and add that directory to CMAKE_PREFIX_PATH.
SET (_snappy_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
SET (_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
SET (CMAKE_INSTALL_PREFIX "${_snappy_install}")
DECLARE_DEP (snappy VERSION 1.1.1 PLATFORMS windows_msvc)
DECLARE_DEP (snappy VERSION 1.1.1-cb2 PLATFORMS centos6 centos7 debian7 debian8 macosx sunos suse11.2 ubuntu12.04 ubuntu14.04 ubuntu16.04 freebsd)
SET (CMAKE_INSTALL_PREFIX "${_orig_install_prefix}")

include(ExternalProject)

### Download, configure and build python-snappy ####################################
ExternalProject_Add(python-snappy
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E echo Configuring python-snappy...

  BUILD_COMMAND python setup.py build build_ext
                -I "${_snappy_install}/include" -L "${_snappy_install}/lib"
  BUILD_IN_SOURCE 1

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND python setup.py install --install-lib <INSTALL_DIR>/lib/python/pysnappy2

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
