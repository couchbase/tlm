# Downloads the declared version of libcouchbase source code and builds it.

include(ExternalProject)

### Download, configure and build libcouchbase ####################################
if (WIN32)
    ExternalProject_Add(libcouchbase
        GIT_REPOSITORY git://github.com/couchbase/libcouchbase.git
        GIT_TAG ${_git_rev}

        CONFIGURE_COMMAND ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/build
        COMMAND cd <SOURCE_DIR>/build && cmake .. -DLCB_NO_PLUGINS=1

        BUILD_COMMAND cd <SOURCE_DIR>/build && cmake --build . --config Release

        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include <INSTALL_DIR>/include
        COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/build/generated <INSTALL_DIR>/include
        COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/bin/
        COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/archive/
        COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/bin/Release
        COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/build/bin/Release/libcouchbase.dll <INSTALL_DIR>/bin/Release/
        COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/archive/Release
        COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/build/lib/Release/libcouchbase.lib <INSTALL_DIR>/archive/Release/
        COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/build/lib/Release/libcouchbase.exp <INSTALL_DIR>/archive/Release/

        COMMAND ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/dbgbuild
        COMMAND cd <SOURCE_DIR>/dbgbuild && cmake .. -DLCB_NO_PLUGINS=1

        COMMAND cd <SOURCE_DIR>/dbgbuild && cmake --build . --config Debug

        COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/bin/Debug
        COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/dbgbuild/bin/Debug/libcouchbase_d.dll <INSTALL_DIR>/bin/Debug/
        COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/archive/Debug
        COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/dbgbuild/lib/Debug/libcouchbase_d.lib <INSTALL_DIR>/archive/Debug/
        COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/dbgbuild/lib/Debug/libcouchbase_d.exp <INSTALL_DIR>/archive/Debug/


        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt <INSTALL_DIR>/CMakeLists.txt
        )


else (WIN32)
    if (APPLE)
        SET(LIBCOUCHBASE_LIBRARY_FILE "<SOURCE_DIR>/build/lib/libcouchbase.dylib")
        SET(LIBCOUCHBASE_DBG_LIBRARY_FILE "<SOURCE_DIR>/dbgbuild/lib/libcouchbase.dylib")
    else (APPLE)
        SET(LIBCOUCHBASE_LIBRARY_FILE "<SOURCE_DIR>/build/lib/libcouchbase.so")
        SET(LIBCOUCHBASE_DBG_LIBRARY_FILE "<SOURCE_DIR>/dbgbuild/lib/libcouchbase.so")
    endif (APPLE)


    _DETERMINE_CPU_COUNT(_parallelism)
    ExternalProject_Add(libcouchbase
        GIT_REPOSITORY git://github.com/couchbase/libcouchbase.git
        GIT_TAG ${_git_rev}

        CONFIGURE_COMMAND ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/build
        COMMAND ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/dbgbuild
        COMMAND cd <SOURCE_DIR>/build && cmake .. -DLCB_NO_PLUGINS=1  -DLCB_BUILD_DTRACE=OFF -DCMAKE_BUILD_TYPE=Release
        COMMAND cd <SOURCE_DIR>/dbgbuild && cmake .. -DLCB_NO_PLUGINS=1 -DLCB_BUILD_DTRACE=OFF -DCMAKE_BUILD_TYPE=Debug

        BUILD_COMMAND cd <SOURCE_DIR> && $(MAKE) -j${_parallelism} -C build
                                      && $(MAKE) -j${_parallelism} -C dbgbuild

        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
        INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include <INSTALL_DIR>/include
        COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/build/generated <INSTALL_DIR>/include
        COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/lib
        COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/lib/Release
        COMMAND ${CMAKE_COMMAND} -E copy ${LIBCOUCHBASE_LIBRARY_FILE} <INSTALL_DIR>/lib/Release/
        COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/lib/Debug
        COMMAND ${CMAKE_COMMAND} -E copy ${LIBCOUCHBASE_DBG_LIBRARY_FILE} <INSTALL_DIR>/lib/Debug

        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists_package.txt <INSTALL_DIR>/CMakeLists.txt
        )

    # OS X-only: Custom post-build step to set the shared library install name.
    if (APPLE)
        ExternalProject_Add_Step(libcouchbase install_name
            COMMAND install_name_tool -id @rpath/libcouchbase.dylib ${LIBCOUCHBASE_LIBRARY_FILE}
            COMMAND install_name_tool -id @rpath/libcouchbase.dylib ${LIBCOUCHBASE_DBG_LIBRARY_FILE}
            DEPENDEES build
            DEPENDERS install
            )
    endif (APPLE)
endif (WIN32)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
