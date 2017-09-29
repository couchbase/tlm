# Downloads the declared version of libevent source code and builds it.

if (APPLE OR WIN32)
  # We bundle OpenSSL on MacOS X and Windows, and we want support
  # for OpenSSL in libevent so we need to install the OpenSSL Package
  SET (_openssl_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
  SET (_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
  SET (CMAKE_INSTALL_PREFIX "${_openssl_install}")
  DECLARE_DEP(openssl VERSION 1.0.2k-cb1 PLATFORMS windows_msvc windows_msvc2015 macosx)
  SET (CMAKE_INSTALL_PREFIX "${_orig_install_prefix}")
  SET (_libevent_extra_options -D OPENSSL_ROOT_DIR=${_openssl_install})
endif (APPLE OR WIN32)

include(ExternalProject)

### Download, configure and build libevent ####################################
ExternalProject_Add(libevent
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D EVENT__BUILD_SHARED_LIBRARIES=ON
             -D EVENT__DISABLE_DEBUG_MODE=ON
             -D EVENT__DISABLE_BENCHMARK=ON
             -D EVENT__DISABLE_TESTS=ON
             -D EVENT__DISABLE_REGRESS=ON
             -D EVENT__DISABLE_SAMPLES=ON
             ${_libevent_extra_options}

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND ${CMAKE_COMMAND} -E remove -f <INSTALL_DIR>/lib/cmake
          COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt <INSTALL_DIR>/CMakeLists.txt
)

# OS X-only: Custom post-build step to set the shared library install name.
if (APPLE)
  ExternalProject_Add_Step(libevent install_name
    COMMAND install_name_tool -id @rpath/libevent.2.1.8.dylib <BINARY_DIR>/lib/libevent.2.1.8.dylib
    COMMAND install_name_tool -id @rpath/libevent_core.2.1.8.dylib <BINARY_DIR>/lib/libevent_core.2.1.8.dylib
    COMMAND install_name_tool -id @rpath/libevent_extra.2.1.8.dylib <BINARY_DIR>/lib/libevent_extra.2.1.8.dylib
    DEPENDEES build
    DEPENDERS install
    WORKING_DIRECTORY <BINARY_DIR>
  )
endif(APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
