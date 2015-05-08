include(ExternalProject)

if (WIN32)
  ExternalProject_Add(gperftools
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}

    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E echo "prep'ing to build"

    # Build in source required for msbuild.
    BUILD_IN_SOURCE 1
    BUILD_COMMAND msbuild /nologo /p:Configuration=Debug /p:Platform=${MSBUILD_ARCH} /maxcpucount:8
                          /t:libtcmalloc_minimal gperftools.sln
          COMMAND msbuild /nologo /p:Configuration=Release /p:Platform=${MSBUILD_ARCH} /maxcpucount:8
                          /t:libtcmalloc_minimal gperftools.sln

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    # Debug and Release libraries (each in their own subdir)
    INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/lib/Debug
            COMMAND ${CMAKE_COMMAND} -E copy ${MSBUILD_ARCH}/Debug/libtcmalloc_minimal.pdb <INSTALL_DIR>/lib/Debug
            COMMAND ${CMAKE_COMMAND} -E copy ${MSBUILD_ARCH}/Debug/libtcmalloc_minimal-debug.lib <INSTALL_DIR>/lib/Debug
            COMMAND ${CMAKE_COMMAND} -E copy ${MSBUILD_ARCH}/Debug/libtcmalloc_minimal-debug.dll <INSTALL_DIR>/lib/Debug

            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/lib/Release
            COMMAND ${CMAKE_COMMAND} -E copy ${MSBUILD_ARCH}/Release/libtcmalloc_minimal.pdb <INSTALL_DIR>/lib/Release
            COMMAND ${CMAKE_COMMAND} -E copy ${MSBUILD_ARCH}/Release/libtcmalloc_minimal.lib <INSTALL_DIR>/lib/Release
            COMMAND ${CMAKE_COMMAND} -E copy ${MSBUILD_ARCH}/Release/libtcmalloc_minimal.dll <INSTALL_DIR>/lib/Release

            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/gperftools
            COMMAND ${CMAKE_COMMAND} -E copy src/gperftools/heap-checker.h <INSTALL_DIR>/include/gperftools
            COMMAND ${CMAKE_COMMAND} -E copy src/gperftools/heap-profiler.h <INSTALL_DIR>/include/gperftools
            COMMAND ${CMAKE_COMMAND} -E copy src/gperftools/malloc_extension.h <INSTALL_DIR>/include/gperftools
            COMMAND ${CMAKE_COMMAND} -E copy src/gperftools/malloc_extension_c.h <INSTALL_DIR>/include/gperftools
            COMMAND ${CMAKE_COMMAND} -E copy src/gperftools/malloc_hook.h <INSTALL_DIR>/include/gperftools
            COMMAND ${CMAKE_COMMAND} -E copy src/gperftools/malloc_hook_c.h <INSTALL_DIR>/include/gperftools
            COMMAND ${CMAKE_COMMAND} -E copy src/gperftools/profiler.h <INSTALL_DIR>/include/gperftools
            COMMAND ${CMAKE_COMMAND} -E copy src/gperftools/stacktrace.h <INSTALL_DIR>/include/gperftools
            COMMAND ${CMAKE_COMMAND} -E copy src/windows/gperftools/tcmalloc.h <INSTALL_DIR>/include/gperftools

            COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt <INSTALL_DIR>/CMakeLists.txt
  )

  # cbdeps boilerplate
  _ADD_PACKAGE_STEP()

endif(WIN32)
