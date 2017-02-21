# Downloads the declared version of libevent source code and builds it.

include(ExternalProject)

### Download, configure and build libevent ####################################
ExternalProject_Add(libevent
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D EVENT__BUILD_SHARED_LIBRARIES=ON
             -D EVENT__DISABLE_DEBUG_MODE=ON
             -D EVENT__DISABLE_OPENSSL=ON
             -D EVENT__DISABLE_BENCHMARK=ON
             -D EVENT__DISABLE_TESTS=ON
             -D EVENT__DISABLE_REGRESS=ON
             -D EVENT__DISABLE_SAMPLES=ON

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
