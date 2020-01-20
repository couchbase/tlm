# Downloads the declared version of libevent source code and builds it.

# We bundle OpenSSL, and we want support for OpenSSL in libevent
# so we need to install the OpenSSL Package

set(_openssl_install "${CMAKE_CURRENT_BINARY_DIR}/unused")
set(_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
set(CMAKE_INSTALL_PREFIX "${_openssl_install}")
declare_dep(openssl VERSION 1.1.1d-cb2
            PLATFORMS amzn2
                      centos7 centos8
                      debian8 debian9 debian10
                      rhel8
                      suse12 suse15
                      ubuntu16.04 ubuntu18.04)
declare_dep (openssl VERSION 1.1.1d-cb1 PLATFORMS macosx windows_msvc2017)

set(CMAKE_INSTALL_PREFIX "${_orig_install_prefix}")
set(_libevent_extra_options -D "OPENSSL_ROOT_DIR=${CMAKE_BINARY_DIR}/libevent/openssl.exploded")

if (APPLE)
  # CMake is supposed to fix this for us, but for some reason libevent
  # does this incorrect (it get replaced as part of make install, and is
  # why we don't use the ExternalProject_Add_Step as it happens _before_
  # make install and the values get stripped again.
  set(_libevent_extra_install_options
      COMMAND install_name_tool -id @rpath/libevent-2.1.7.dylib <INSTALL_DIR>/lib/libevent-2.1.7.dylib
      COMMAND install_name_tool -id @rpath/libevent_core-2.1.7.dylib <INSTALL_DIR>/lib/libevent_core-2.1.7.dylib
      COMMAND install_name_tool -id @rpath/libevent_extra-2.1.7.dylib <INSTALL_DIR>/lib/libevent_extra-2.1.7.dylib
      COMMAND install_name_tool -change <INSTALL_DIR>/lib/libevent_core-2.1.7.dylib @rpath/libevent_core-2.1.7.dylib <INSTALL_DIR>/lib/libevent_extra-2.1.7.dylib

      COMMAND install_name_tool -id @rpath/libevent_openssl-2.1.7.dylib <INSTALL_DIR>/lib/libevent_openssl-2.1.7.dylib
      COMMAND install_name_tool -change <INSTALL_DIR>/lib/libevent_core-2.1.7.dylib @rpath/libevent_core-2.1.7.dylib <INSTALL_DIR>/lib/libevent_openssl-2.1.7.dylib
      COMMAND install_name_tool -id @rpath/libevent_pthreads-2.1.7.dylib <INSTALL_DIR>/lib/libevent_pthreads-2.1.7.dylib
      COMMAND install_name_tool -change <INSTALL_DIR>/lib/libevent_core-2.1.7.dylib @rpath/libevent_core-2.1.7.dylib <INSTALL_DIR>/lib/libevent_pthreads-2.1.7.dylib
      )
elseif(UNIX)
  # We want to set the RUNPATH to ${ORIGIN} to make sure that it search
  # the current directory first for the dependencies (openssl etc)
  set(_libevent_extra_options
      ${_libevent_extra_options}
      -DCMAKE_INSTALL_RPATH=\$ORIGIN/../lib)

  # We don't want all of the archives to be present
  set(_libevent_extra_install_options
      COMMAND ${CMAKE_COMMAND} -E remove -f <INSTALL_DIR>/lib/libevent.a
      COMMAND ${CMAKE_COMMAND} -E remove -f <INSTALL_DIR>/lib/libevent_core.a
      COMMAND ${CMAKE_COMMAND} -E remove -f <INSTALL_DIR>/lib/libevent_extra.a
      COMMAND ${CMAKE_COMMAND} -E remove -f <INSTALL_DIR>/lib/libevent_openssl.a
      COMMAND ${CMAKE_COMMAND} -E remove -f <INSTALL_DIR>/lib/libevent_pthreads.a)
endif()

set(_libevent_build_type RelWithDebInfo)

include(ExternalProject)

### Download, configure and build libevent ####################################
ExternalProject_Add(libevent
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D CMAKE_BUILD_TYPE=${_libevent_build_type}
             -D EVENT__DISABLE_BENCHMARK=ON
             -D EVENT__DISABLE_TESTS=ON
             -D EVENT__DISABLE_REGRESS=ON
             -D EVENT__DISABLE_SAMPLES=ON
             ${_libevent_extra_options}

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND ${CMAKE_COMMAND} -E remove -f <INSTALL_DIR>/lib/cmake
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/pkgconfig
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/cmake
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/bin
          COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt <INSTALL_DIR>/CMakeLists.txt
          ${_libevent_extra_install_options}
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
