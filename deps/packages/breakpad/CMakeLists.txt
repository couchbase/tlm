# Downloads the declared version of breakpad source code and builds it.

include(ExternalProject)

### Download, configure and build breakpad ####################################

IF (WIN32)
  ExternalProject_Add(breakpad
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}

    # Configure:
    # win_{release,debug}_RuntimeLibrary: Breakpad defaults to building static
    # variants (/MT and /MTd) whereas we need the DLL variants.
    CONFIGURE_COMMAND <SOURCE_DIR>/src/tools/gyp/gyp.bat
                      <SOURCE_DIR>/src/client/windows/breakpad_client.gyp
                      --no-circular-check
                      -D win_release_RuntimeLibrary=2
                      -D win_debug_RuntimeLibrary=3

    # Build in source required for msbuild.
    BUILD_IN_SOURCE 1
    BUILD_COMMAND msbuild /p:Configuration=Debug /p:Platform=${MSBUILD_ARCH} /maxcpucount
                          src/client/windows/breakpad_client.sln
          COMMAND msbuild /p:Configuration=Release /p:Platform=${MSBUILD_ARCH} /maxcpucount
                          src/client/windows/breakpad_client.sln

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    # Debug and Release libraries (each in their own subdir)
    INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/lib/Debug
            COMMAND ${CMAKE_COMMAND} -E copy src/client/windows/Debug/lib/common.lib <INSTALL_DIR>/lib/Debug
            COMMAND ${CMAKE_COMMAND} -E copy src/client/windows/Debug/lib/crash_generation_client.lib <INSTALL_DIR>/lib/Debug
            COMMAND ${CMAKE_COMMAND} -E copy src/client/windows/Debug/lib/exception_handler.lib <INSTALL_DIR>/lib/Debug

            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/lib/Release
            COMMAND ${CMAKE_COMMAND} -E copy src/client/windows/Release/lib/common.lib <INSTALL_DIR>/lib/Release
            COMMAND ${CMAKE_COMMAND} -E copy src/client/windows/Release/lib/crash_generation_client.lib <INSTALL_DIR>/lib/Release
            COMMAND ${CMAKE_COMMAND} -E copy src/client/windows/Release/lib/exception_handler.lib <INSTALL_DIR>/lib/Release

    # Header files. Unfortunately normal Windows commands (xcopy etc) don't
    # like the Unix-style directory seperators which CMake uses, and CMake's
    # builtin copy / copy_directory commands don't support wildcards so we
    # end up with quite a long, explicit list...
            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/breakpad/client/windows/common
            COMMAND ${CMAKE_COMMAND} -E copy src/client/windows/common/ipc_protocol.h
                                             <INSTALL_DIR>/include/breakpad/client/windows/common/

            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/breakpad/client/windows/crash_generation
            COMMAND ${CMAKE_COMMAND} -E copy src/client/windows/crash_generation/crash_generation_client.h
                                             <INSTALL_DIR>/include/breakpad/client/windows/crash_generation

            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/breakpad/client/windows/handler
            COMMAND ${CMAKE_COMMAND} -E copy src/client/windows/handler/exception_handler.h
			                                 <INSTALL_DIR>/include/breakpad/client/windows/handler/

            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/breakpad/common
            COMMAND ${CMAKE_COMMAND} -E copy src/common/scoped_ptr.h
                                             <INSTALL_DIR>/include/breakpad/common/

            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/breakpad/common/windows
            COMMAND ${CMAKE_COMMAND} -E copy src/common/windows/string_utils-inl.h
                                             <INSTALL_DIR>/include/breakpad/common/windows/

            COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include/breakpad/google_breakpad/common
            COMMAND ${CMAKE_COMMAND} -E copy_directory src/google_breakpad/common/
                                                       <INSTALL_DIR>/include/breakpad/google_breakpad/common/

    # On WIN32 don't actually need to package any breakpad files - everything used is statically
    # linked into our files.
            COMMAND ${CMAKE_COMMAND} -E echo "" > <INSTALL_DIR>/CMakeLists.txt
  )

ELSE (WIN32)

  SET(BREAKPAD_LDFLAGS -Wl,-rpath=\\$$ORIGIN/../lib)

  ExternalProject_Add(breakpad
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG ${_git_rev}

    CONFIGURE_COMMAND autoreconf -i
              COMMAND <SOURCE_DIR>/configure LDFLAGS=${BREAKPAD_LDFLAGS} --prefix=<INSTALL_DIR>

    # Build in source so breakpad correctly detects it git version.
    BUILD_IN_SOURCE 1
    BUILD_COMMAND $(MAKE)

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    INSTALL_COMMAND $(MAKE) install
    COMMAND ${CMAKE_COMMAND} -E echo FILE "(COPY bin/minidump-2-core DESTINATION \"\${CMAKE_INSTALL_PREFIX}/bin\")" > <INSTALL_DIR>/CMakeLists.txt
  )
ENDIF(WIN32)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
