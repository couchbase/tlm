include(ExternalProject)

_DETERMINE_CPU_COUNT(_parallelism)

list(APPEND cache_args ${common_cmake_cache_args})
list(APPEND cache_args -DCMAKE_CXX_VISIBILITY_PRESET:STRING=hidden)
list(APPEND cache_args -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON)

ExternalProject_Add(fmt
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}

  CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
	     -D CMAKE_BUILD_TYPE=RelWithDebInfo
         # Explicilty set LIBDIR to 'lib' so for single linux
         # builds (CentOS 7) we don't put the libraries under
         # `lib64` which is not a default search path for
         # find_package() when we later consume this cbdep.
         -D CMAKE_INSTALL_LIBDIR=lib

  CMAKE_CACHE_ARGS ${cache_args}
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}

  TEST_BEFORE_INSTALL 1

  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
