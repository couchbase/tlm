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
if(WIN32)
   declare_dep(jemalloc VERSION 4.1.0-cb2 PLATFORMS ${PLATFORM})
else(WIN32)
   declare_dep(jemalloc VERSION 4.5.0.1-cb1 PLATFORMS ${PLATFORM})
endif(WIN32)
declare_dep(libevent VERSION 2.1.8-cb4 PLATFORMS ${PLATFORM})
if(WIN32)
   declare_dep(snappy VERSION 1.1.1 PLATFORMS ${PLATFORM})
else(WIN32)
   declare_dep(snappy VERSION 1.1.1-cb2 PLATFORMS ${PLATFORM})
endif(WIN32)
declare_dep(zlib VERSION 1.2.11-cb3 PLATFORMS ${PLATFORM})

if (APPLE)
   declare_dep(openssl VERSION 1.0.2k-cb3 PLATFORMS macosx)
endif(APPLE)
if(WIN32)
   declare_dep(openssl VERSION 1.0.2k-cb2 PLATFORMS windows_msvc2015)
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

if(WIN32)
   # GFlags / Glog: we build it statically, but gflags / glog headers default
   # to defining all public symbols as dllimport which results in linker
   # errors - the compiler is expecting dll(shared) symbols and not static.
   # Explicitly define GFLAGS_DLL_DEFINE_FLAG / GOOGLE_GLOG_DLL_DECL as
   # empty to avoid this.
   set(folly_extra_cache_args "-DCMAKE_CXX_FLAGS:STRING=-DGFLAGS_DLL_DEFINE_FLAG= -DGOOGLE_GLOG_DLL_DECL=")

   # Folly code generation (GenerateFingerprintTables.exe) needs to run
   # at build-time; and to do so it needs the runtime dependancies of folly
   # (including libevent!) in its path. It's problematic to modify
   # Windows PATH from inside CMake; so solve this by simply copying
   # the runtime dependancies into the Folly build directory.
   set(folly_patch_command ${CMAKE_COMMAND} -E copy_directory ${_folly_deps_install}/bin <SOURCE_DIR>)
endif()

ExternalProject_Add(folly
  GIT_REPOSITORY ${_git_repo}
  GIT_TAG ${_git_rev}
  PATCH_COMMAND ${folly_patch_command}
  CMAKE_CACHE_ARGS -DCMAKE_INCLUDE_PATH:STRING=${folly_include_paths}
                   -DCMAKE_LIBRARY_PATH:STRING=${folly_library_paths}
                   -DCMAKE_PREFIX_PATH:STRING=${CMAKE_CURRENT_BINARY_DIR}/gflags.exploded
                   ${folly_extra_cache_args}
  CMAKE_ARGS -D CMAKE_BUILD_TYPE=RelWithDebInfo
             -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
             -D BUILD_SHARED_LIBS=OFF
             -D Boost_DETAILED_FAILURE_MSG=ON
             -D Boost_USE_STATIC_LIBS=ON
  BUILD_IN_SOURCE 1
  INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
  )

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
