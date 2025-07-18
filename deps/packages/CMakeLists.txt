# Project for building the third-party dependencies for Couchbase Server.
#
# Note that this project is not intended to be run as part of a
# Couchbase Server build. It is included in the Couchbase Server
# source code for reference (as these are the steps taken to produce
# the pre-packaged dependencies which are downloaded as part of the
# Couchbase Server build) as well as to make it easier to build
# Couchbase Server on novel platforms.

#
# The following are the variables set by this script:
# HOST_ARCH
# PLATFORM

CMAKE_MINIMUM_REQUIRED(VERSION 3.16)

LIST (APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../../cmake/Modules")
INCLUDE (CouchbaseSelectCompiler)

PROJECT (cbdeps_packages)

INCLUDE (PlatformIntrospection)
INCLUDE (CBDownloadDeps)
INCLUDE (CouchbaseCompilerOptions)

# Generate a .md5 file
MACRO (_ADD_MD5_FILE_STEP sourcefile md5file package)
  ExternalProject_Add_Step (${package} md5
    COMMAND "${CMAKE_COMMAND}"
    -D "FILE=${sourcefile}"
    -D "MD5FILE=${md5file}"
    -P "${PROJECT_SOURCE_DIR}/util/GenMD5.cmake"
    DEPENDEES package)
ENDMACRO (_ADD_MD5_FILE_STEP)


# Macro intended to be called by package sub-projects to provide
# the ExternalPackage "package" step.
MACRO (_ADD_PACKAGE_STEP)
  ExternalProject_Add_Step(${_dep_package} package
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_output_dir}
    COMMAND ${CMAKE_COMMAND} -E tar czf ${_output_file}.tgz .
    COMMENT "Performing packaging step for '${_dep_package}' - writing artifacts to ${_output_dir}"
    DEPENDEES install
    WORKING_DIRECTORY <INSTALL_DIR>
    )
  _ADD_MD5_FILE_STEP(${_output_file}.tgz ${_output_file}.md5 ${_dep_package})

  if (CB_DOWNLOAD_DEPS_CACHE)
    SET(_cached_file_base "${CB_DOWNLOAD_DEPS_CACHE}/${_output_file_name}")
    SET(_cached_file "${_cached_file_base}.tgz")
    SET(_cached_md5 "${_cached_file_base}.md5")
    SET(_target build-and-cache-${_dep_package})

    _CHECK_CACHED_DEP_FILE("${_cached_file}" "${_cached_md5}" _dep_found)
    if (_dep_found)
      ADD_CUSTOM_TARGET(${_target}
        COMMAND ${CMAKE_COMMAND} -E echo "Seems like you already have ${_cached_file}"
        COMMAND ${CMAKE_COMMAND} -E echo "If that is not the case please regenerate cmake files"
        COMMAND ${CMAKE_COMMAND} -E echo "If you want to rebuild the dependency, just delete the file")
    else ()
      ADD_CUSTOM_TARGET(${_target}
        COMMAND ${CMAKE_COMMAND} -E copy "${_output_file}.tgz" "${_cached_file}"
        COMMAND ${CMAKE_COMMAND} -E copy "${_output_file}.md5" "${_cached_md5}"
        DEPENDS ${_dep_package})
    endif ()

    ADD_DEPENDENCIES(build-and-cache-all ${_target})
  endif ()
ENDMACRO (_ADD_PACKAGE_STEP)

# Macro to standardize several steps in sub-projects.
# Args:
#   package - name of the third-party package. It is expected that a
#     a subdirectory of the current directory exists with this name,
#     containing a CMakeLists which defines an ExternalProject of
#     the same name. The ExternalProject must have all steps up to
#     and including "install" fully defined, and then call
#     _ADD_PACKAGE_STEP() to complete the packaging.
#   upstream_ver - the version of the upstream project to build. This
#     is strictly a label; it will be used to determine the resulting
#     cbdeps package name.
#   cb_branch - all source will be retrieved from
#      github.com/couchbasedeps/<package>. This parameter determines
#      the branch / tag / SHA to check out.
#   cb_release - a numeric index, which should be advanced whenever we
#      need to re-package a given dependency while maintaining the same
#      upstream_ver.
# If the CMake variable 'PACKAGE' is defined but not equal to package,
# this macro will do nothing. This allows incremental building of packages
# on a new platform.
#
MACRO (_ADD_DEP_PACKAGE package upstream_ver cb_branch cb_release)
  IF (NOT DEFINED PACKAGE OR "${PACKAGE}" STREQUAL "${package}")
    IF (WIN32)
      # All Windows cbdeps packages should just be called "windows", even
      # though PLATFORM is eg. windows_msvc2017. Having PLATFORM include
      # the compiler version is important for routing builds to the right
      # Jenkins agents, but not for the resulting package name.
      SET (_pkg_plat windows)
    ELSEIF (CB_DEP_TARGET_PLATFORM)
      # For certain groups of platforms (currently Linux
      # distributions) we build a single cbdep package which is used
      # for multiple different distributions - e.g. centos7 and
      # ubuntu20.04 can all use a package targetting "linux".
      # Similary for architecture-neutral packages (say only
      # containing Java bytecode) we use the platform "all".
      #
      # Therefore, allow the platform of the output package to be
      # overridden by setting CB_DEP_TARGET_PLATFORM.
      SET (_pkg_plat ${CB_DEP_TARGET_PLATFORM})
    ELSE ()
      SET (_pkg_plat ${PLATFORM})
    ENDIF ()
    SET (_output_file_name "${package}-${_pkg_plat}-${HOST_ARCH}-${upstream_ver}-cb${cb_release}")
    SET (_output_dir "${CMAKE_BINARY_DIR}/deps/${package}/${upstream_ver}-cb${cb_release}")
    SET (_output_file "${_output_dir}/${_output_file_name}")
    SET (_git_repo "https://github.com/couchbasedeps/${package}.git")
    SET (_git_rev ${cb_branch})
    SET (_dep_package ${package})
    SET (_dep_version ${upstream_ver})
    ADD_SUBDIRECTORY (${package})
  ENDIF (NOT DEFINED PACKAGE OR "${PACKAGE}" STREQUAL "${package}")
ENDMACRO (_ADD_DEP_PACKAGE)


#
# Standard code run on include to perform common checks and setup useful vars
#
_DETERMINE_ARCH(HOST_ARCH)
# Use the "most specific" local platform name, since we need a single value
# here for putting into filenames
_DETERMINE_PLATFORM(PLATFORM)
IF (PLATFORM STREQUAL "unknown")
  MESSAGE (FATAL_ERROR "Cannot build cbdeps on unrecognized platform!")
ENDIF ()
MESSAGE (STATUS "Set platform to ${PLATFORM} and arch to ${HOST_ARCH} for building cbdeps package")

#
# Check for autotools stuff, as many of the deps require them.
#
IF (NOT WIN32)
   FIND_PROGRAM(AUTOMAKE automake)
   IF (NOT AUTOMAKE)
      MESSAGE(WARNING "Building many packages requires automake")
   ENDIF (NOT AUTOMAKE)
   FIND_PROGRAM(AUTOCONF autoconf)
   IF (NOT AUTOCONF)
       MESSAGE(WARNING "Building many packages requires autoconf")
   ENDIF (NOT AUTOCONF)
   FIND_PROGRAM(LIBTOOLIZE libtoolize)
   IF (NOT LIBTOOLIZE)
       FIND_PROGRAM(GLIBTOOLIZE glibtoolize)
       IF (GLIBTOOLIZE)
           MESSAGE(FATAL_ERROR "No libtoolize found, but there is a glibtoolize. You should try to create a symbolic link")
       ENDIF (GLIBTOOLIZE)
       MESSAGE(WARNING "Building many packages requires libtoolize")
   ENDIF (NOT LIBTOOLIZE)
   FIND_PROGRAM(AUTORECONF autoreconf)
   IF (NOT AUTORECONF)
       MESSAGE(WARNING "Building many packages requires autoreconf")
   ENDIF (NOT AUTORECONF)
ENDIF (NOT WIN32)

# msbuild uses a different names for architecture (compared to HOST_ARCH)
if (WIN32)
  if(HOST_ARCH STREQUAL "amd64")
    SET(MSBUILD_ARCH "x64")
  elseif(HOST_ARCH STREQUAL "x86")
    SET(MSBUILD_ARCH "Win32")
  else(HOST_ARCH STREQUAL "amd64")
    SET(MSBUILD_ARCH ${HOST_ARCH})
  endif(HOST_ARCH STREQUAL "amd64")
endif(WIN32)

# Common CMake cache arguments for all packages to set compiler and C++ standard version
# to avoid duplicating this in each of the individual package CMakeLists.txt files.
list(APPEND common_cmake_cache_args -DCMAKE_CXX_STANDARD:STRING=17)
list(APPEND common_cmake_cache_args -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER})
list(APPEND common_cmake_cache_args -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER})

if (APPLE)
    # As of Morpheus the oldest supported target is 13
    list(APPEND common_cmake_cache_args -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=13)
endif ()

ADD_CUSTOM_TARGET(build-and-cache-all)

#
# And here is the set of "latest" dependencies.
#
_ADD_DEP_PACKAGE(snappy 1.1.10 1.1.10 3)
_ADD_DEP_PACKAGE(python-snappy c97d633 c97d633 2)
_ADD_DEP_PACKAGE(icu4c 59.1 r59.1 4)
_ADD_DEP_PACKAGE(libevent 2.1.11 release-2.1.11-stable 12)

_ADD_DEP_PACKAGE(libsqlite3 3.7.2 3.7.2 1)

_ADD_DEP_PACKAGE(flatbuffers v1.10.0 v1.10.0 7)

_ADD_DEP_PACKAGE(json 3.11.3 v3.11.3 2)
_ADD_DEP_PACKAGE(boost 1.82.0 boost-1.82.0 6)

IF (CMAKE_SYSTEM_NAME STREQUAL "Linux")
  IF (PLATFORM STREQUAL "fedora26" OR PLATFORM STREQUAL "fedora27")
    _ADD_DEP_PACKAGE(libcxx 4.0.0 release_40 1)
  ELSE ()
    _ADD_DEP_PACKAGE(libcxx 3.9.1 release_39 2)
  ENDIF ()
ENDIF ()
_ADD_DEP_PACKAGE(numactl 2.0.11 v2.0.11 4)

# maven 3.5.2-cb3 and 3.5.2-cb4 exist as attempts to make Windows work,
# but are not correct.
_ADD_DEP_PACKAGE(maven 3.5.2 master 7)
_ADD_DEP_PACKAGE(openjdk-rt 1.8.0.171 UNUSED 2)

_ADD_DEP_PACKAGE(double-conversion 3.3.0 v3.3.0 1)
_ADD_DEP_PACKAGE(fmt 11.0.0 11.0.0 2)
_ADD_DEP_PACKAGE(glog v0.4.0 v0.4.0 3)
_ADD_DEP_PACKAGE(benchmark v1.9.1 v1.9.1 1)
_ADD_DEP_PACKAGE(googletest 1.15.2 1.15.2 1)
_ADD_DEP_PACKAGE(fuzztest v2025-02-14 v2025-02-14-couchbase 2)

_ADD_DEP_PACKAGE(folly v2022.05.23.00-couchbase v2022.05.23.00-couchbase 1_avx2)
_ADD_DEP_PACKAGE(grpc 1.59.3 v1.59.3 1)
_ADD_DEP_PACKAGE(pcre 8.44 v8.44 4)
_ADD_DEP_PACKAGE(prometheus-cpp v1.2.1-couchbase v1.2.1-couchbase 1)
_ADD_DEP_PACKAGE(spdlog v1.15.0 v1.15.0 4)
