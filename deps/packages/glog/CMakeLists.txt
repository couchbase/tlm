include(ExternalProject)

ExternalProject_Add(glog
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  BUILD_IN_SOURCE 1
  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D CMAKE_BUILD_TYPE=RelWithDebInfo
             -D BUILD_SHARED_LIBS=OFF

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/cmake
)

# Additionally build a Debug variant on Windows, as for a debug build of
# CB Server we need all dependancies _also_ linked against Debug CRT.
if (WIN32)
  ExternalProject_Add(glog_WinDebugCRT
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}
    BUILD_IN_SOURCE 1
    CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
               -D CMAKE_BUILD_TYPE=Debug
               -D BUILD_SHARED_LIBS=OFF
    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy glog.lib <INSTALL_DIR>/lib/glogd.lib
  )
  ExternalProject_Add_StepDependencies(glog download glog_WinDebugCRT)
endif()

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
