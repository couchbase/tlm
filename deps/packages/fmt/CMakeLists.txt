include(ExternalProject)

_DETERMINE_CPU_COUNT(_parallelism)

ExternalProject_Add(fmt
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
	     -D CMAKE_BUILD_TYPE=RelWithDebInfo
         -D CMAKE_CXX_VISIBILITY_PRESET=hidden
         -D CMAKE_POSITION_INDEPENDENT_CODE=ON

  BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}

  TEST_BEFORE_INSTALL 1

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
)

# Additionally build a Debug variant on Windows, as for a debug build of
# CB Server we need all dependancies _also_ linked against Debug CRT.
if (WIN32)
   ExternalProject_Add(fmt_WinDebugCRT
     GIT_REPOSITORY ${_git_repo}
     GIT_TAG ${_git_rev}

     CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
                -D CMAKE_BUILD_TYPE=Debug
                -D CMAKE_CXX_VISIBILITY_PRESET=hidden
                -D CMAKE_POSITION_INDEPENDENT_CODE=ON

     BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}

     TEST_BEFORE_INSTALL 1

     INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
     INSTALL_COMMAND $(MAKE) install
   )
   ExternalProject_Add_StepDependencies(fmt download fmt_WinDebugCRT)
endif()

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
