# Downloads the declared version of libsnappy source code and builds it.

include(PlatformIntrospection)
include(ExternalProject)
include(CheckCXXCompilerFlag)

_DETERMINE_CPU_COUNT(_parallelism)

# Create a list of args that we want to pass to any snappy build.
set(cxx_flags)

if (UNIX)
   check_cxx_compiler_flag(-march=x86-64-v3 HAVE_MARCH_X86_64_V3)
   if (HAVE_MARCH_X86_64_V3)
       message(STATUS "Building with -march=x86-64-v3")
       set(cxx_flags "${cxx_flags} -march=x86-64-v3")
   else()
       _DETERMINE_ARCH(HOST_ARCH)
       if (${HOST_ARCH} STREQUAL x86_64)
         message(FATAL_ERROR "Can't build with g++ on x86_64 without support for -march=x86-64-v3")
       endif()
   endif()

   list(APPEND cache_args ${common_cmake_cache_args})
endif()
list(APPEND cache_args -DCMAKE_CXX_FLAGS:STRING=${cxx_flags})
list(APPEND cache_args -DCMAKE_INSTALL_LIBDIR:STRING=lib)
list(APPEND cache_args -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo)
list(APPEND cache_args -DBUILD_SHARED_LIBS:BOOL=ON)
list(APPEND cache_args -DSNAPPY_HAVE_BMI2:BOOL=NO)
list(APPEND cache_args -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR}/install)
list(APPEND cache_args -DTEST_BEFORE_INSTALL:BOOL=OFF)
list(APPEND cache_args -DSNAPPY_BUILD_BENCHMARKS:BOOL=OFF)
list(APPEND cache_args -DSNAPPY_BUILD_TESTS:BOOL=OFF)
list(APPEND cache_args -DCMAKE_INSTALL_RPATH:STRING='\$ORIGIN')


### Download, configure and build snappy ####################################
### snappy.patch is applied to address the following
### 1. Build failure for Clang 13.0+.
###    https://groups.google.com/g/snappy-compression/c/zwzPUj_TKwY
### 2. RTTI is disabled by default in snappy 1.1.9.  We need to comment this out.
###    https://github.com/google/snappy/pull/147#issuecomment-1011335649
### 3. Set CMAKE_MINIMUM_REQUIRED to 3.30 to support newer CMake versions.
ExternalProject_Add(snappy
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  PATCH_COMMAND git apply ${CMAKE_CURRENT_SOURCE_DIR}/snappy.patch
  CMAKE_CACHE_ARGS ${cache_args}
  BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
          COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt" <INSTALL_DIR>/CMakeLists.txt
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
