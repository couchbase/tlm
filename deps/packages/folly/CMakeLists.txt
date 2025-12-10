# Downloads the declared version of Folly builds it.
include(PlatformIntrospection)
include(ExternalProject)
include(CheckCXXCompilerFlag)

# Expand folly's deps to a separate install directory so we don't end up
# packaging them up in the folly cbdep itself.
set(_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
set(_folly_deps_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
set(CMAKE_INSTALL_PREFIX "${_folly_deps_install}")

DECLARE_DEP (boost VERSION 1.86.0-cb3 PLATFORMS linux macosx windows)
DECLARE_DEP (double-conversion VERSION 3.3.0-cb1 PLATFORMS linux macosx windows)
DECLARE_DEP (fast_float V2 VERSION 7.0.0 BUILD 1 PLATFORMS linux macosx windows)
DECLARE_DEP (fmt VERSION 11.0.0-cb2 PLATFORMS linux macosx windows)
DECLARE_DEP (gflags V2 VERSION 2.2.2 BUILD 1 PLATFORMS linux macosx windows)
DECLARE_DEP (glog VERSION v0.4.0-cb3 PLATFORMS linux macosx windows_msvc2015 windows)
DECLARE_DEP (jemalloc V2 VERSION 5.3.0 BUILD 14 PLATFORMS linux macosx windows)
DECLARE_DEP (libevent VERSION 2.1.11-cb12 PLATFORMS linux macosx windows)
DECLARE_DEP (openssl V2 VERSION 3.1.4 BUILD 1 PLATFORMS linux macosx windows)
DECLARE_DEP (zlib V2 VERSION 1.2.13 BUILD 2 PLATFORMS linux macosx windows)

# Restore the INSTALL_PREFIX
set(CMAKE_INSTALL_PREFIX ${_orig_install_prefix})

# Add all of the exploaded headers, and the installed libs to folly's search
# paths.
file(GLOB folly_include_paths
    ${CMAKE_CURRENT_BINARY_DIR}/*.exploded/include)
file(GLOB folly_library_paths
    ${CMAKE_CURRENT_BINARY_DIR}/*.exploded/lib
    ${CMAKE_CURRENT_BINARY_DIR}/*.exploded/lib64)
list(APPEND folly_library_paths ${_folly_deps_install}/lib)

# Platform-specific settings
set(cxx_flags "")
set(folly_patch_command "")

if(UNIX)
   list(APPEND cache_args ${common_cmake_cache_args})
   set(cxx_flags "-fPIC -fvisibility=hidden")

   # Require x86-64-v3 microarchitecture on x86_64 platforms
   check_cxx_compiler_flag(-march=x86-64-v3 HAVE_MARCH_X86_64_V3)
   if(HAVE_MARCH_X86_64_V3)
       message(STATUS "Building with -march=x86-64-v3")
       string(APPEND cxx_flags " -march=x86-64-v3")
   else()
       _DETERMINE_ARCH(HOST_ARCH)
       if(HOST_ARCH STREQUAL "x86_64")
           message(FATAL_ERROR "Can't build with g++ on x86_64 without support for -march=x86-64-v3")
       endif()
   endif()

   if(APPLE)
       # Apple clang automatically adds -I/usr/local/include which can pick up
       # Homebrew's fmt (e.g. from `brew install ccache`). Use -idirafter to push
       # /usr/local/include to the END of the search order.
       set(cxx_flags "-idirafter /usr/local/include ${cxx_flags}")
   endif()

   list(APPEND cache_args "-DCMAKE_CXX_FLAGS:STRING=${cxx_flags}")

elseif(WIN32)
   # Glog/Gflags: we build statically, but headers default to dllimport.
   # MSVC2022 requires '/utf-8'.
   list(APPEND cache_args "-DCMAKE_CXX_FLAGS:STRING=/utf-8 -DGOOGLE_GLOG_DLL_DECL= -DGFLAGS_DLL_DECLARE_FLAG=")

   # Folly code generation (GenerateFingerprintTables.exe) needs runtime
   # dependencies in its path. Copy them into the build directory.
   set(folly_patch_command ${CMAKE_COMMAND} -E copy_directory
           ${_folly_deps_install}/bin <SOURCE_DIR>)
endif()

# Common cache args for all platforms
list(APPEND cache_args -DCMAKE_LIBRARY_PATH:STRING=${folly_library_paths})
list(APPEND cache_args -DCMAKE_INCLUDE_PATH:STRING=${folly_include_paths})
list(APPEND cache_args -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo)
list(APPEND cache_args "-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR}/install")
list(APPEND cache_args -DBUILD_SHARED_LIBS:STRING=OFF)
list(APPEND cache_args -DCMAKE_PREFIX_PATH:STRING=${CMAKE_CURRENT_BINARY_DIR}/fmt.exploded)
list(APPEND cache_args -DCMAKE_POLICY_VERSION_MINIMUM:STRING=3.5)

# Boost settings
list(APPEND cache_args -DBoost_ADDITIONAL_VERSIONS:STRING=1.86)
list(APPEND cache_args -DBoost_DETAILED_FAILURE_MSG:STRING=ON)
list(APPEND cache_args -DBoost_USE_STATIC_LIBS:STRING=ON)
list(APPEND cache_args -DBoost_NO_SYSTEM_PATHS:BOOL=ON)
list(APPEND cache_args -DBoost_NO_BOOST_CMAKE:BOOL=ON)
list(APPEND cache_args -DBOOST_ROOT:STRING=${CMAKE_CURRENT_BINARY_DIR}/boost.exploded)
# Keep using FindBoost module (CMP0167 NEW would remove it)
list(APPEND cache_args -DCMAKE_POLICY_DEFAULT_CMP0167:STRING=OLD)

# fmt settings
list(APPEND cache_args -Dfmt_ROOT:STRING=${CMAKE_CURRENT_BINARY_DIR}/fmt.exploded)
list(APPEND cache_args -Dfmt_DIR:STRING=${CMAKE_CURRENT_BINARY_DIR}/fmt.exploded/lib/cmake/fmt)
# Ensure we find our exploded fmt, not any system-installed version
list(APPEND cache_args -DCMAKE_POLICY_DEFAULT_CMP0074:STRING=NEW)

# Disable optional packages we don't need
list(APPEND cache_args -DCMAKE_DISABLE_FIND_PACKAGE_BZip2:BOOL=TRUE)
list(APPEND cache_args -DCMAKE_DISABLE_FIND_PACKAGE_LibLZMA:BOOL=TRUE)
list(APPEND cache_args -DCMAKE_DISABLE_FIND_PACKAGE_Zstd:BOOL=TRUE)
list(APPEND cache_args -DCMAKE_DISABLE_FIND_PACKAGE_LZ4:BOOL=TRUE)
list(APPEND cache_args -DCMAKE_DISABLE_FIND_PACKAGE_Snappy:BOOL=TRUE)
list(APPEND cache_args -DCMAKE_DISABLE_FIND_PACKAGE_LibDwarf:BOOL=TRUE)
list(APPEND cache_args -DCMAKE_DISABLE_FIND_PACKAGE_Libiberty:BOOL=TRUE)
list(APPEND cache_args -DCMAKE_DISABLE_FIND_PACKAGE_LibAIO:BOOL=TRUE)
list(APPEND cache_args -DCMAKE_DISABLE_FIND_PACKAGE_LibUring:BOOL=TRUE)
list(APPEND cache_args -DCMAKE_DISABLE_FIND_PACKAGE_Libsodium:BOOL=TRUE)

_DETERMINE_CPU_COUNT(_parallelism)

# Somebody working on folly decided to add a template parameter to SharedMutex
# that defaults to whether or not folly was compiled with or without TSan. This
# is a pain for us because we will need different symbols based on whether or
# not we are compiling with TSan. Solve this problem by building and shipping
# a 'libfollytsan.a' compiled with an additional '-fsanitize=thread' flag that
# we can link additionally on the platforms where we will run TSan.
ExternalProject_Add(folly
        GIT_REPOSITORY ${_git_repo}
        GIT_TAG ${_git_rev}
        PATCH_COMMAND ${folly_patch_command}
        CMAKE_ARGS  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
        CMAKE_CACHE_ARGS ${cache_args}
        BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}
        BUILD_IN_SOURCE 1
        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt <INSTALL_DIR>/CMakeLists.txt
        )

# We generally only run TSan on linux containers, but on occasion a local build is
# required. Only build the TSan package on linux and macos platforms to save
# time.
if (UNIX)
   # Not designed to be built independently of the normal folly package build. The
   # build will only install the package and not the source.
   ExternalProject_Add(follytsan
        GIT_REPOSITORY ${_git_repo}
        GIT_TAG ${_git_rev}
        PATCH_COMMAND ${folly_patch_command}
        CMAKE_ARGS  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
        CMAKE_CACHE_ARGS ${cache_args}
            "-DCMAKE_CXX_FLAGS:STRING=${cxx_flags} -fsanitize=thread"
        BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}
        BUILD_IN_SOURCE 1
        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        INSTALL_COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/install/lib &&
        cp libfolly.a ${CMAKE_CURRENT_BINARY_DIR}/install/lib/libfollytsan.a
        )
   ExternalProject_Add_StepDependencies(folly download follytsan)

   # Not designed to be built independently of the normal folly package build. The
   # build will only install the package and not the source.
   ExternalProject_Add(folly.asan
            GIT_REPOSITORY ${_git_repo}
            GIT_TAG ${_git_rev}
            PATCH_COMMAND ${folly_patch_command}
            CMAKE_ARGS  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
            CMAKE_CACHE_ARGS ${cache_args}
                -DCMAKE_BUILD_TYPE:STRING=DebugOptimized
                "-DCMAKE_CXX_FLAGS:STRING=${cxx_flags} -fsanitize=address"
            BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}
            BUILD_IN_SOURCE 1
            INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
            INSTALL_COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/install/lib &&
            cp libfolly.a ${CMAKE_CURRENT_BINARY_DIR}/install/lib/libfollyasan.a
            )
   ExternalProject_Add_StepDependencies(folly download folly.asan)
endif()

# Additionally build a Debug variant for macOS / Linux.
if(UNIX)
  ExternalProject_Add(folly.debug
        GIT_REPOSITORY ${_git_repo}
        GIT_TAG ${_git_rev}
        PATCH_COMMAND ${folly_patch_command}
        CMAKE_ARGS  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
        CMAKE_CACHE_ARGS ${cache_args}
            -DCMAKE_BUILD_TYPE:STRING=Debug
            -DCMAKE_DEBUG_POSTFIX:STRING=d
        BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}
        BUILD_IN_SOURCE 1
        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        )
  ExternalProject_Add_StepDependencies(folly download folly.debug)
endif()

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
