# Downloads the declared version of Folly builds it.
include(ExternalProject)

# Expand folly's deps to a separate install directory so we don't end up
# packaging them up in the folly cbdep itself.
set(_orig_install_prefix "${CMAKE_INSTALL_PREFIX}")
set(_folly_deps_install "${CMAKE_CURRENT_BINARY_DIR}/dep-install")
set(CMAKE_INSTALL_PREFIX "${_folly_deps_install}")

declare_dep(boost VERSION 1.67.0-cb3 PLATFORMS ${PLATFORM})
declare_dep(double-conversion VERSION 3.0.0-cb2 PLATFORMS ${PLATFORM})
declare_dep(gflags VERSION 2.2.1-cb2 PLATFORMS ${PLATFORM})
declare_dep(glog VERSION 0.3.5-cb1 PLATFORMS ${PLATFORM})
declare_dep(jemalloc VERSION 5.1.0-cb4 PLATFORMS ${PLATFORM})
declare_dep(libevent VERSION 2.1.8-cb4 PLATFORMS ${PLATFORM})
if(WIN32)
   declare_dep(snappy VERSION 1.1.1 PLATFORMS ${PLATFORM})
else(WIN32)
   declare_dep(snappy VERSION 1.1.1-cb2 PLATFORMS ${PLATFORM})
endif(WIN32)
declare_dep(zlib V2 VERSION 1.2.11 BUILD 4 PLATFORMS ${PLATFORM})

if(WIN32)
   declare_dep(openssl VERSION 1.0.2k-cb2 PLATFORMS windows_msvc2017)
else(WIN32)
   declare_dep(openssl VERSION 1.1.1b-cb2 PLATFORMS centos7 debian8 macosx)
endif(WIN32)

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
set(cxx_flags "-fPIC")
set(cache_args -DCMAKE_LIBRARY_PATH:STRING=${folly_library_paths})
list(APPEND cache_args -DCMAKE_INCLUDE_PATH:STRING=${folly_include_paths})
list(APPEND cache_args "-DCMAKE_PREFIX_PATH:STRING=\
${CMAKE_CURRENT_BINARY_DIR}/gflags.exploded")
list(APPEND cache_args -DCMAKE_CXX_FLAGS:STRING=${cxx_flags})
list(APPEND cache_args -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo)
list(APPEND cache_args "-DCMAKE_INSTALL_PREFIX:PATH=\
${CMAKE_CURRENT_BINARY_DIR}/install")
list(APPEND cache_args -DBUILD_SHARED_LIBS:STRING=OFF)
list(APPEND cache_args -DBoost_DETAILED_FAILURE_MSG:STRING=ON)
list(APPEND cache_args -DBoost_USE_STATIC_LIBS:STRING=ON)
list(APPEND cache_args -DCXX_STD:STRING=c++14)

if(WIN32)
   # GFlags / Glog: we build it statically, but gflags / glog headers default
   # to defining all public symbols as dllimport which results in linker
   # errors - the compiler is expecting dll(shared) symbols and not static.
   # Explicitly define GFLAGS_DLL_DEFINE_FLAG / GOOGLE_GLOG_DLL_DECL as
   # empty to avoid this.
   list(APPEND cache_args "-DCMAKE_CXX_FLAGS:STRING= -DGFLAGS_DLL_DEFINE_FLAG= \
    -DGOOGLE_GLOG_DLL_DECL=")

   # Folly code generation (GenerateFingerprintTables.exe) needs to run
   # at build-time; and to do so it needs the runtime dependancies of folly
   # (including libevent!) in its path. It's problematic to modify
   # Windows PATH from inside CMake; so solve this by simply copying
   # the runtime dependancies into the Folly build directory.
   set(folly_patch_command ${CMAKE_COMMAND} -E copy_directory
           ${_folly_deps_install}/bin <SOURCE_DIR>)
endif()

# Somebody working on folly decided to add a template parameter to SharedMutex
# that defaults to whether or not folly was compiled with or without TSan. This
# is a pain for us because we will need different symbols based on whether or
# not we are compiling with TSan. Solve this problem by building and shipping
# a 'libfollytsan.a' compiled with an additional '-fsanitize=thread' flag that
# we can link additionally on the platforms where we will run TSan.

# Not designed to be built independently of the normal folly package build. The
# build will only install the package and not the source.
ExternalProject_Add(follytsan
        GIT_REPOSITORY ${_git_repo}
        GIT_TAG ${_git_rev}
        PATCH_COMMAND ${folly_patch_command}
        CMAKE_CACHE_ARGS ${cache_args}
            -DCMAKE_CXX_FLAGS:STRING=${cxx_flags}\ -fsanitize=thread
        BUILD_IN_SOURCE 1
        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        INSTALL_COMMAND mkdir ${CMAKE_CURRENT_BINARY_DIR}/install/lib &&
        cp libfolly.a ${CMAKE_CURRENT_BINARY_DIR}/install/lib/libfollytsan.a
        )

ExternalProject_Add(folly
        GIT_REPOSITORY ${_git_repo}
        GIT_TAG ${_git_rev}
        PATCH_COMMAND ${folly_patch_command}
        CMAKE_CACHE_ARGS ${cache_args}
        BUILD_IN_SOURCE 1
        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        )

# We generally only run TSan on ubuntu dockers, but on occasion a local build is
# required. Only build the TSan package on ubuntu and macos platforms to save
# time.
if (${PLATFORM} MATCHES "ubuntu" OR ${PLATFORM} MATCHES "macos")
   ExternalProject_Add_StepDependencies(folly download follytsan)
endif()

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
