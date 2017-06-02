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

PROJECT (cbdeps_packages)

CMAKE_MINIMUM_REQUIRED (VERSION 2.8)

LIST (APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../../cmake/Modules")
INCLUDE (PlatformIntrospection)
INCLUDE (CBDownloadDeps)

_DETERMINE_PLATFORM (cbcache_platform)
_DETERMINE_ARCH (cbcache_arch)

MESSAGE (STATUS "Set platform to ${cbcache_platform} for dependency downloads")
MESSAGE (STATUS "Set arch to ${cbcache_arch} for dependency downloads")

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
    SET(_cached_file "${CB_DOWNLOAD_DEPS_CACHE}/${_output_file_name}.tgz")
    SET(_cached_md5 "${_cached_file}.md5")
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
    SET (_output_file_name "${package}-${PLATFORM}-${HOST_ARCH}-${upstream_ver}-cb${cb_release}")
    SET (_output_dir "${CMAKE_BINARY_DIR}/deps/${package}/${upstream_ver}-cb${cb_release}")
    SET (_output_file "${_output_dir}/${_output_file_name}")
    SET (_git_repo "git://github.com/couchbasedeps/${package}.git")
    SET (_git_rev ${cb_branch})
    SET (_dep_package ${package})
    ADD_SUBDIRECTORY (${package})
  ENDIF (NOT DEFINED PACKAGE OR "${PACKAGE}" STREQUAL "${package}")
ENDMACRO (_ADD_DEP_PACKAGE)


#
# Standard code run on include to perform common checks and setup useful vars
#
_DETERMINE_ARCH(HOST_ARCH)
_DETERMINE_PLATFORM(PLATFORM)

#
# Check for autotools stuff, as many of the deps require them.
#
IF (NOT WIN32)
   FIND_PROGRAM(AUTOMAKE automake)
   IF (NOT AUTOMAKE)
      MESSAGE(FATAL_ERROR "Building packages requires automake")
   ENDIF (NOT AUTOMAKE)
   FIND_PROGRAM(AUTOCONF autoconf)
   IF (NOT AUTOCONF)
       MESSAGE(FATAL_ERROR "Building packages requires autoconf")
   ENDIF (NOT AUTOCONF)
   FIND_PROGRAM(LIBTOOLIZE libtoolize)
   IF (NOT LIBTOOLIZE)
       FIND_PROGRAM(GLIBTOOLIZE glibtoolize)
       IF (GLIBTOOLIZE)
           MESSAGE(FATAL_ERROR "No libtoolize found, but there is a glibtoolize. You should try to create a symbolic link")
       ENDIF (GLIBTOOLIZE)
       MESSAGE(FATAL_ERROR "Building packages requires libtoolize")
   ENDIF (NOT LIBTOOLIZE)
   FIND_PROGRAM(AUTORECONF autoreconf)
   IF (NOT AUTORECONF)
       MESSAGE(FATAL_ERROR "Building packages requires autoreconf")
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

ADD_CUSTOM_TARGET(build-and-cache-all)

#
# And here is the set of "latest" dependencies.
#
IF (CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Windows")
   _ADD_DEP_PACKAGE(breakpad 20160926 20160926-couchbase 1)
ELSE (CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Windows")
   MESSAGE(STATUS "Skipping breakpad for ${CMAKE_SYSTEM_NAME}")
ENDIF (CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Windows")
_ADD_DEP_PACKAGE(snappy 1.1.1 1.1.1 2)
_ADD_DEP_PACKAGE(python-snappy c97d633 c97d633 1)
_ADD_DEP_PACKAGE(icu4c 54.1 r54.1 10)
_ADD_DEP_PACKAGE(libevent 2.1.8 release-2.1.8-stable-cb 2)
_ADD_DEP_PACKAGE(v8 5.2 5.2-couchbase 2)
_ADD_DEP_PACKAGE(jemalloc 4.3.1 4.3.1 2)
_ADD_DEP_PACKAGE(curl 7.49.1 curl-7_49_1 1)

# erlang R16B03-couchbase / branch: couchbase-watson
# - SHA 96430ba for R16B03-couchbase-cb1 release
# - SHA 00852da for R16B03-couchbase-cb2 release
# - SHA 1f768b7 for R16B03-1-couchbase-cb2 release (Windows only)
# - SHA 3ea8397 for R16B03-1-couchbase-cb3 release (all platforms but Windows)
# - SHA 3ea8397 for R16B03-1-couchbase-cb4 release (Windows only - cb3 on Windows
#     mistakenly built from wrong branch)
_ADD_DEP_PACKAGE(erlang R16B03-1-couchbase couchbase-watson 4)

_ADD_DEP_PACKAGE(libsqlite3 3.7.2 3.7.2 1)
_ADD_DEP_PACKAGE(flatbuffers 1.4.0 v1.4.0 1)
_ADD_DEP_PACKAGE(json 1.1.0 v1.1.0 1)
_ADD_DEP_PACKAGE(boost 1.62.0 v1.62.0 3)
IF (APPLE)
  _ADD_DEP_PACKAGE(openssl_h 0.9.8za 0.9.8za 1)
ENDIF ()
IF (WIN32)
  _ADD_DEP_PACKAGE(openssl 1.0.2k OpenSSL_1_0_2k 1)
ENDIF (WIN32)
_ADD_DEP_PACKAGE(libcouchbase 2.7.5 2.7.5 1)
