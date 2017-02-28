# Downloads the declared version of pysqlite2 source code and builds it.

# First, download the dependency: libsqlite3 itself. Set CMAKE_INSTALL_PREFIX
# to a local directory to dump in there, and add that directory to CMAKE_PREFIX_PATH.
IF (NOT APPLE)
  SET (_libsqlite3_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
  SET (_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
  SET (CMAKE_INSTALL_PREFIX "${_libsqlite3_install}")
  DECLARE_DEP (libsqlite3 VERSION 3.7.2-cb1 PLATFORMS centos6 centos7 debian7 debian8 suse11.2 ubuntu12.04 ubuntu14.04 ubuntu16.04 freebsd)
  SET (CMAKE_INSTALL_PREFIX "${_orig_install_prefix}")
ENDIF (NOT APPLE)

include(ExternalProject)

### Download, configure and build pysqlite2 ####################################
ExternalProject_Add(pysqlite2
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E echo Configuring pysqlite2...

  BUILD_COMMAND python setup.py config
                -I "${_libsqlite3_install}/include" -L "${_libsqlite3_install}/lib" build
  BUILD_IN_SOURCE 1

  INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/install"
  INSTALL_COMMAND python setup.py install --install-lib <INSTALL_DIR>/lib/python
                --install-data "${CMAKE_CURRENT_BINARY_DIR}/ignore"
          COMMAND "${CMAKE_COMMAND}" -E remove_directory <INSTALL_DIR>/lib/python/pysqlite2/test

  COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY lib DESTINATION \"\${CMAKE_INSTALL_PREFIX}\")" > <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
