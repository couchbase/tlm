# Downloads the declared version of libsnappy source code and builds it.

include(ExternalProject)

_DETERMINE_CPU_COUNT(_parallelism)

### Download, configure and build snappy ####################################
### snappy.patch is applied to address the following
### 1. Build failure for Clang 13.0+.
###    https://groups.google.com/g/snappy-compression/c/zwzPUj_TKwY
### 2. RTTI is disabled by default in snappy 1.1.9.  We need to comment this out.
###    https://github.com/google/snappy/pull/147#issuecomment-1011335649

ExternalProject_Add(snappy
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  PATCH_COMMAND git apply ${CMAKE_CURRENT_SOURCE_DIR}/snappy.patch
  CMAKE_ARGS -D CMAKE_C_FLAGS_RELWITHDEBINFO=${CMAKE_C_FLAGS_RELWITHDEBINFO}
             -D CMAKE_CXX_FLAGS_RELWITHDEBINFO=${CMAKE_CXX_FLAGS_RELWITHDEBINFO}
             -D CMAKE_INSTALL_LIBDIR=lib
             -D CMAKE_BUILD_TYPE=RelWithDebInfo
             -D BUILD_SHARED_LIBS=ON
             -D SNAPPY_HAVE_BMI2=NO
             -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D TEST_BEFORE_INSTALL=OFF
             -D SNAPPY_BUILD_BENCHMARKS=OFF
             -D SNAPPY_BUILD_TESTS=OFF

  BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
          COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt" <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
