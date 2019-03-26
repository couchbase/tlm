include(ExternalProject)

### Download, configure and build libevent ####################################
ExternalProject_Add(opentracing-cpp
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D CMAKE_BUILD_TYPE=RelWithDebInfo
             -D BUILD_SHARED_LIBS=ON
             -D BUILD_STATIC_LIBS=OFF
             -D BUILD_MOCKTRACER=OFF
             -D BUILD_DYNAMIC_LOADING=ON

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/cmake
          COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt <INSTALL_DIR>/CMakeLists.txt
)

IF (WIN32)
  # Hide the .dll so that the build will only find it in the installed
  # location, not in the exploded dir
  ExternalProject_Add_Step(opentracing-cpp hide-lib
    COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/dll
    COMMAND ${CMAKE_COMMAND} -E rename <INSTALL_DIR>/lib/opentracing.dll <INSTALL_DIR>/dll/opentracing.dll
    DEPENDEES install
  )
ENDIF ()

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
