# Downloads the declared version of flatbuffers source code and builds it.

include(ExternalProject)

# set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-copy"

if (CMAKE_COMPILER_IS_GNUCC AND (NOT(CMAKE_CXX_COMPILER_VERSION LESS 7.3.0)))
    SET(FLATBUFFERS_COMPILER_OPTIONS "-DCMAKE_CXX_FLAGS:STRING=-Wno-error=implicit-fallthrough")
endif()

### Download, configure and build flatbuffers ####################################
ExternalProject_Add(flatbuffers
  BUILD_IN_SOURCE 1
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  PATCH_COMMAND git apply ${CMAKE_CURRENT_SOURCE_DIR}/macos_disable_werror.patch
  CMAKE_CACHE_ARGS -DCMAKE_INSTALL_PREFIX:STRING=${CMAKE_CURRENT_BINARY_DIR}/install
                   ${FLATBUFFERS_COMPILER_OPTIONS}
  CMAKE_ARGS -D FLATBUFFERS_BUILD_TESTS=OFF
             -D CMAKE_BUILD_TYPE=Release
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND $(MAKE) install
          COMMAND ${CMAKE_COMMAND} -E echo "" > <INSTALL_DIR>/CMakeLists.txt
)

# Additionally build a Debug variant on Windows, as for a debug build of
# CB Server we need all dependancies _also_ linked against Debug CRT.
if (WIN32)
  ExternalProject_Add(flatbuffers_WinDebugCRT
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}
    BUILD_IN_SOURCE 1
    CMAKE_CACHE_ARGS -DCMAKE_INSTALL_PREFIX:STRING=${CMAKE_CURRENT_BINARY_DIR}/install
                     ${FLATBUFFERS_COMPILER_OPTIONS}
    CMAKE_ARGS -D FLATBUFFERS_BUILD_TESTS=OFF
             -D CMAKE_BUILD_TYPE=Debug
    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy flatbuffers.lib <INSTALL_DIR>/lib/flatbuffersd.lib
  )
  ExternalProject_Add_StepDependencies(flatbuffers download flatbuffers_WinDebugCRT)
endif()


# cbdeps boilerplate
_ADD_PACKAGE_STEP()
