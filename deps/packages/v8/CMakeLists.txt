# Downloads the declared version of v8 source code and builds it.

include(ExternalProject)

SET(_gyp_flags "-Dcomponent=shared_library"
               "-Dv8_enable_backtrace=1"
               "-Dv8_use_snapshot='true'"
               "-Dv8_use_external_startup_data=0"
               "-Dv8_enable_i18n_support=1"
               "-Dtest_isolation_mode=noop"
               "-Dwerror=-Wno-error")
string(REPLACE ";" " " GYP_FLAGS "${_gyp_flags}")


if (APPLE)
   SET(V8_LIBRARY_FILE "<SOURCE_DIR>/out/x64.release/libv8.dylib")
else (APPLE)
   SET(V8_LIBRARY_FILE "<SOURCE_DIR>/out/x64.release/lib.target/libv8.so")
   SET(GYP_FLAGS "${GYP_FLAGS} -Dclang=0")

   if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
     FIND_PROGRAM(_ld_gold NAMES ld.gold)
     if (_ld_gold)
       EXECUTE_PROCESS(COMMAND ${_ld_gold} --version
         OUTPUT_VARIABLE _ld_gold_version
         ERROR_QUIET)
       STRING(REGEX MATCH "GNU Binutils .*[0-9.]+\\)" _binutils_version_full "${_ld_gold_version}")
       if (_binutils_version_full)
         STRING(REGEX MATCH "[0-9.]+" _binutils_version "${_binutils_version_full}")

         if (NOT (_binutils_version VERSION_LESS "2.25"))
           MESSAGE(STATUS "Binutils version ${_binutils_version}")
           MESSAGE(STATUS "Binutils version is at least 2.25, "
             "cannot use bundled binutils")
           SET(GYP_FLAGS "${GYP_FLAGS} -Dlinux_use_bundled_gold=0 -Dlinux_use_bundled_binutils=0")
         endif ()
       else ()
         MESSAGE(WARNING "Couldn't figure out binutils version. The build might fail")
       endif ()
     endif ()
   endif ()
endif (APPLE)

### Download, configure and build v8 ####################################
IF (WIN32)
  IF (${MSBUILD_ARCH} STREQUAL "x64")
    SET(_arch_suffix "_x64")
    SET(V8_TARGET_ARCH "x64")
  ELSEIF (${MSBUILD_ARCH} STREQUAL "Win32")
    SET(_arch_suffix "")
    SET(V8_TARGET_ARCH "ia32")
  ENDIF ()
  SET(V8_BUILD_DIR_RELEASE "out\\Release${_arch_suffix}")
  SET(V8_BUILD_DIR_DEBUG "out\\Debug${_arch_suffix}")
  SET(V8_LIBRARY_DIR_RELEASE "<SOURCE_DIR>/out/Release${_arch_suffix}")
  SET(V8_LIBRARY_DIR_DEBUG "<SOURCE_DIR>/out/Debug${_arch_suffix}")
  SET(V8_STATIC_DIR_RELEASE "<SOURCE_DIR>/out/Release${_arch_suffix}/obj/src")
  SET(V8_STATIC_DIR_DEBUG "<SOURCE_DIR>/out/Debug${_arch_suffix}/obj/src")

  ExternalProject_Add(v8
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}
    BUILD_IN_SOURCE 1

    CONFIGURE_COMMAND ${CMAKE_COMMAND} -DV8_TARGET_ARCH=${V8_TARGET_ARCH} -P ${CMAKE_CURRENT_SOURCE_DIR}/v8win.cmake
    BUILD_COMMAND "ninja" "-C" ${V8_BUILD_DIR_RELEASE} "v8" "v8_libplatform"
          COMMAND "ninja" "-C" ${V8_BUILD_DIR_DEBUG} "v8" "v8_libplatform"

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install

    INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include
            COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include <INSTALL_DIR>/include
            COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/third_party/icu/source/common/unicode <INSTALL_DIR>/include/unicode
            COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/third_party/icu/source/i18n/unicode <INSTALL_DIR>/include/unicode
            COMMAND ${CMAKE_COMMAND} -E remove -f <INSTALL_DIR>/include/OWNERS

            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/lib/Release
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/v8.dll <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/v8.dll.exp <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/v8.dll.lib <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/v8.dll.pdb <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/icui18n.dll <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/icui18n.dll.exp <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/icui18n.dll.lib <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/icui18n.dll.pdb <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/icuuc.dll <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/icuuc.dll.exp <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/icuuc.dll.lib <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/icuuc.dll.pdb <INSTALL_DIR>/lib/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_RELEASE}/icudt.dll <INSTALL_DIR>/lib/Release/

            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/lib/Debug
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/v8.dll <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/v8.dll.exp <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/v8.dll.lib <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/v8.dll.pdb <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/icui18n.dll <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/icui18n.dll.exp <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/icui18n.dll.lib <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/icui18n.dll.pdb <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/icuuc.dll <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/icuuc.dll.exp <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/icuuc.dll.lib <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/icuuc.dll.pdb <INSTALL_DIR>/lib/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_DIR_DEBUG}/icudt.dll <INSTALL_DIR>/lib/Debug/

            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/archive/Release
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_STATIC_DIR_RELEASE}/v8_libplatform.lib <INSTALL_DIR>/archive/Release/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_STATIC_DIR_RELEASE}/v8_libbase.lib <INSTALL_DIR>/archive/Release/
            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/archive/Debug
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_STATIC_DIR_DEBUG}/v8_libplatform.lib <INSTALL_DIR>/archive/Debug/
            COMMAND ${CMAKE_COMMAND} -E copy ${V8_STATIC_DIR_DEBUG}/v8_libbase.lib <INSTALL_DIR>/archive/Debug/

            COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt <INSTALL_DIR>/CMakeLists.txt
  )
ELSE (WIN32)
  _DETERMINE_CPU_COUNT(_parallelism)
  ExternalProject_Add(v8
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}
    BUILD_IN_SOURCE 1

    CONFIGURE_COMMAND cd <SOURCE_DIR>/build

    BUILD_COMMAND $(MAKE) -j${_parallelism} x64.release GYPFLAGS+=${GYP_FLAGS} CFLAGS+=-DDEBUG CPPFLAGS+=-DDEBUG PYTHONPATH=<SOURCE_DIR>/third_party/argparse-1.4.0
    IF (APPLE)
        COMMAND install_name_tool -id @rpath/libv8.dylib <SOURCE_DIR>/out/x64.release/libv8.dylib
    ENDIF (APPLE)

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install

    INSTALL_COMMAND mkdir -p <INSTALL_DIR>/lib/Release <INSTALL_DIR>/lib/Debug <INSTALL_DIR>/include
    COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_FILE} <INSTALL_DIR>/lib/Release
    COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include <INSTALL_DIR>/include
    COMMAND ${CMAKE_COMMAND} -E remove -f <INSTALL_DIR>/include/OWNERS

    COMMAND ${CMAKE_COMMAND} -E remove -f ${V8_LIBRARY_FILE}
    COMMAND $(MAKE) -j${_parallelism} x64.release GYPFLAGS+=${GYP_FLAGS} GYPFLAGS+="-Drelease_extra_cflags=-ggdb3" CFLAGS+=-DDEBUG CPPFLAGS+=-DDEBUG PYTHONPATH=<SOURCE_DIR>/third_party/argparse-1.4.0
    IF (APPLE)
        COMMAND install_name_tool -id @rpath/libv8.dylib <SOURCE_DIR>/out/x64.release/libv8.dylib
    ENDIF (APPLE)
    COMMAND ${CMAKE_COMMAND} -E copy ${V8_LIBRARY_FILE} <INSTALL_DIR>/lib/Debug

    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt <INSTALL_DIR>/CMakeLists.txt
)
ENDIF (WIN32)


# Add icu from couchbasedps/icu4c.git
ExternalProject_Add_Step(v8 get_icu
  COMMAND cd <SOURCE_DIR>/third_party/icu && git clone git://github.com/couchbasedeps/icu4c.git -b r54.1
  COMMAND ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/third_party/icu/source
  COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/third_party/icu/icu4c/source <SOURCE_DIR>/third_party/icu/source
  COMMAND ${CMAKE_COMMAND} -E remove_directory <SOURCE_DIR>/third_party/icu/icu4c
  DEPENDEES configure
  DEPENDERS build
)

#SUSE only: Custom pre-build step to copy in correct local version of nm.
if ("${cbcache_platform}" MATCHES "^suse.*")
  ExternalProject_Add_Step(v8 move_nm
    COMMAND cp -a /usr/bin/nm <SOURCE_DIR>/third_party/binutils/Linux_x64/Release/bin
    DEPENDEES configure
    DEPENDERS build
  )
endif ("${cbcache_platform}" MATCHES "^suse.*")

# OS X-only: Custom post-build step to set the shared library install name.
# We also need to copy clang to a special location.
if (APPLE)
  ExternalProject_Add_Step(v8 move_clang
    COMMAND cp -a /usr/bin/clang <SOURCE_DIR>/third_party/llvm-build/Release+Asserts/bin
    COMMAND cp -a /usr/bin/clang++ <SOURCE_DIR>/third_party/llvm-build/Release+Asserts/bin
    DEPENDEES configure
    DEPENDERS build
  )
endif (APPLE)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
