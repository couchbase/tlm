# Downloads the declared version of python-snappy source code and builds it.

# First, download the dependency: snappy itself. Set CMAKE_INSTALL_PREFIX
# to a local directory to dump in there, and add that directory to CMAKE_PREFIX_PATH.
SET (_snappy_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
SET (_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
SET (CMAKE_INSTALL_PREFIX "${_snappy_install}")
IF (WIN32)
  MESSAGE (FATAL_ERROR "python-snappy > 1.1.1 cannot be built on Windows")
ELSE ()
  DECLARE_DEP (snappy VERSION 1.1.6-cb1 PLATFORMS centos6 centos7 debian8 debian9 macosx sunos suse11.2 suse12.2 ubuntu14.04 ubuntu16.04 freebsd)
ENDIF ()
SET (CMAKE_INSTALL_PREFIX "${_orig_install_prefix}")

include(ExternalProject)

### Download, configure and build python-snappy ####################################
ExternalProject_Add(python-snappy
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E echo Configuring python-snappy...

  BUILD_COMMAND python setup.py build build_ext
                -I "${CMAKE_CURRENT_BINARY_DIR}/snappy.exploded/include" -L "${_snappy_install}/lib"
  BUILD_IN_SOURCE 1

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND python setup.py install --install-lib <INSTALL_DIR>/lib/python/pysnappy2

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
