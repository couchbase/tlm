# Downloads the declared version of libsnappy source code and builds it.

include(ExternalProject)

_DETERMINE_CPU_COUNT(_parallelism)

### Download, configure and build snappy ####################################
ExternalProject_Add(snappy
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CMAKE_ARGS -D CMAKE_C_FLAGS_RELWITHDEBINFO=${CMAKE_C_FLAGS_RELWITHDEBINFO}
             -D CMAKE_CXX_FLAGS_RELWITHDEBINFO=${CMAKE_CXX_FLAGS_RELWITHDEBINFO}
             -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D CMAKE_BUILD_TYPE=RelWithDebInfo
             -D BUILD_SHARED_LIBS=ON

  BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}

  TEST_BEFORE_INSTALL ON

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
          COMMAND ${CMAKE_COMMAND} -E echo "file(GLOB snappy_libs lib/*snappy*)" > <INSTALL_DIR>/CMakeLists.txt
          COMMAND ${CMAKE_COMMAND} -E echo "file(COPY \${snappy_libs} DESTINATION \"\${CMAKE_INSTALL_PREFIX}/lib/\")" >> <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
