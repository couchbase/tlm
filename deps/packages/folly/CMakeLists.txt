# Downloads the declared version of Folly builds it.
include(ExternalProject)

# Expand folly's deps to a separate install directory so we don't end up
# packaging them up in the folly cbdep itself.
set(_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
set(_folly_deps_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
set(CMAKE_INSTALL_PREFIX "${_folly_deps_install}")

# Due to a full rebuild of all the RHEL 8 cbdeps using GCC 7.3.0
# (previously using GCC 8.2.1), the following temporary conditionals
# are needed for said platform, and can be removed once things are
# resynced with a later build.
DECLARE_DEP (boost VERSION 1.67.0-cb8 PLATFORMS amzn2 centos7 centos8 debian8 debian9 debian10 macosx rhel8 suse12 suse15 ubuntu16.04 ubuntu18.04 windows_msvc2017)
DECLARE_DEP (double-conversion VERSION 3.0.0-cb2 PLATFORMS amzn2 centos6 centos7 debian8 debian9 macosx suse12 suse15 ubuntu16.04 ubuntu18.04 windows_msvc2015 windows_msvc2017)
DECLARE_DEP (double-conversion VERSION 3.0.0-cb4 PLATFORMS centos8 debian10 rhel8)
DECLARE_DEP (glog VERSION 0.3.5-cb4 PLATFORMS amzn2 centos6 centos7 centos8 debian8 debian9 debian10 macosx rhel8 suse12 suse15 ubuntu16.04 ubuntu18.04 windows_msvc2015 windows_msvc2017)
DECLARE_DEP (jemalloc VERSION 5.2.1-cb1 PLATFORMS amzn2 centos7 centos8 debian7 debian8 debian9 debian10 macosx rhel8 suse12 suse15 ubuntu16.04 ubuntu18.04 windows_msvc2017)
DECLARE_DEP (libevent VERSION 2.1.8-cb8 PLATFORMS amzn2 centos7 debian8 debian9 macosx suse12 suse15 ubuntu16.04 ubuntu18.04 windows_msvc2017)
DECLARE_DEP (libevent VERSION 2.1.8-cb10 PLATFORMS centos8 debian10 rhel8)
DECLARE_DEP (openssl VERSION 1.1.1d-cb1 PLATFORMS amzn2 centos7 centos8 debian8 debian9 debian10 macosx rhel8 suse12 suse15 ubuntu16.04 ubuntu18.04 windows_msvc2017)
DECLARE_DEP (snappy VERSION 1.1.1 PLATFORMS windows_msvc2015 windows_msvc2017)
DECLARE_DEP (snappy VERSION 1.1.1-cb2 PLATFORMS amzn2 centos6 centos7 debian8 debian9 macosx suse11 suse12 suse15 ubuntu14.04 ubuntu16.04 ubuntu18.04)
DECLARE_DEP (snappy VERSION 1.1.1-cb5 PLATFORMS centos8 debian10 rhel8)
DECLARE_DEP (zlib V2 VERSION 1.2.11 BUILD 4 PLATFORMS amzn2 centos7 debian8 debian9 macosx suse12 suse15 ubuntu16.04 ubuntu18.04 windows_msvc2017)
DECLARE_DEP (zlib V2 VERSION 1.2.11 BUILD 6 PLATFORMS centos8 debian10 rhel8)

# Restore the INSTALL_PREFIX
set(CMAKE_INSTALL_PREFIX ${_orig_install_prefix})

# Add all of the exploaded headers, and the installed libs to folly's search
# paths.
file(GLOB folly_include_paths
     ${CMAKE_CURRENT_BINARY_DIR}/*.exploded/include)
file(GLOB folly_library_paths
        ${CMAKE_CURRENT_BINARY_DIR}/*.exploded/lib)
list(APPEND folly_library_paths ${_folly_deps_install}/lib)

# Create a list of args that we want to pass to any folly build.
set(cxx_flags "-fPIC -fvisibility=hidden")
set(cache_args -DCMAKE_LIBRARY_PATH:STRING=${folly_library_paths})
list(APPEND cache_args -DCMAKE_INCLUDE_PATH:STRING=${folly_include_paths})
list(APPEND cache_args -DCMAKE_CXX_FLAGS:STRING=${cxx_flags})
list(APPEND cache_args -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo)
list(APPEND cache_args "-DCMAKE_INSTALL_PREFIX:PATH=\
${CMAKE_CURRENT_BINARY_DIR}/install")
list(APPEND cache_args -DBUILD_SHARED_LIBS:STRING=OFF)
list(APPEND cache_args -DBoost_DETAILED_FAILURE_MSG:STRING=ON)
list(APPEND cache_args -DBoost_USE_STATIC_LIBS:STRING=ON)
list(APPEND cache_args -DCXX_STD:STRING=c++17)

if(WIN32)
   # Glog: we build it statically, but glog headers default
   # to defining all public symbols as dllimport which results in linker
   # errors - the compiler is expecting dll(shared) symbols and not static.
   # Explicitly define GOOGLE_GLOG_DLL_DECL as empty to avoid this.
   list(APPEND cache_args "-DCMAKE_CXX_FLAGS:STRING= -DGOOGLE_GLOG_DLL_DECL=")

   # Folly code generation (GenerateFingerprintTables.exe) needs to run
   # at build-time; and to do so it needs the runtime dependancies of folly
   # (including libevent!) in its path. It's problematic to modify
   # Windows PATH from inside CMake; so solve this by simply copying
   # the runtime dependancies into the Folly build directory.
   set(folly_patch_command ${CMAKE_COMMAND} -E copy_directory
           ${_folly_deps_install}/bin <SOURCE_DIR>)
endif()

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
              COMMAND git reset --hard
              COMMAND git apply ${CMAKE_CURRENT_SOURCE_DIR}/folly_gflags_optional.patch
        CMAKE_CACHE_ARGS ${cache_args}
        BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}
        BUILD_IN_SOURCE 1
        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        )

# We generally only run TSan on ubuntu dockers, but on occasion a local build is
# required. Only build the TSan package on ubuntu and macos platforms to save
# time.
if (${PLATFORM} MATCHES "ubuntu" OR ${PLATFORM} MATCHES "macos")
   # Not designed to be built independently of the normal folly package build. The
   # build will only install the package and not the source.
   ExternalProject_Add(follytsan
        GIT_REPOSITORY ${_git_repo}
        GIT_TAG ${_git_rev}
        PATCH_COMMAND ${folly_patch_command}
              COMMAND git reset --hard
              COMMAND git apply ${CMAKE_CURRENT_SOURCE_DIR}/folly_gflags_optional.patch
        CMAKE_CACHE_ARGS ${cache_args}
            -DCMAKE_CXX_FLAGS:STRING=${cxx_flags}\ -fsanitize=thread
        BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}
        BUILD_IN_SOURCE 1
        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        INSTALL_COMMAND mkdir -p ${CMAKE_CURRENT_BINARY_DIR}/install/lib &&
        cp libfolly.a ${CMAKE_CURRENT_BINARY_DIR}/install/lib/libfollytsan.a
        )
   ExternalProject_Add_StepDependencies(folly download follytsan)
endif()

# Additionally build a Debug variant on Windows, as for a debug build of
# CB Server we need all dependancies _also_ linked against Debug CRT.
if (WIN32)
   ExternalProject_Add(folly_WinDebugCRT
        GIT_REPOSITORY ${_git_repo}
        GIT_TAG ${_git_rev}
        PATCH_COMMAND ${folly_patch_command}
              COMMAND git reset --hard
              COMMAND git apply ${CMAKE_CURRENT_SOURCE_DIR}/folly_gflags_optional.patch
        CMAKE_CACHE_ARGS ${cache_args}
            -DCMAKE_BUILD_TYPE:STRING=Debug
        BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}
        BUILD_IN_SOURCE 1
        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        INSTALL_COMMAND cmake -E copy folly.lib ${CMAKE_CURRENT_BINARY_DIR}/install/lib/follyd.lib
        )
   ExternalProject_Add_StepDependencies(folly download folly_WinDebugCRT)
endif()

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
