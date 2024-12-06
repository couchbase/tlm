include(ExternalProject)

_DETERMINE_CPU_COUNT(_parallelism)

DECLARE_DEP (fmt VERSION 11.0.2-cb1 PLATFORMS linux macosx windows)

# Given we build spdlog twice on Windows, define the common cmake
# arguments once.
list(APPEND cache_args -DCMAKE_CXX_VISIBILITY_PRESET:STRING=hidden)
list(APPEND cache_args -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON)
list(APPEND cache_args -DSPDLOG_BUILD_EXAMPLE:BOOL=OFF)

# Use the same (external) fmtlib library as the rest of the server build.
list(APPEND cache_args -DSPDLOG_FMT_EXTERNAL:BOOL=ON)
list(APPEND cache_args -DCMAKE_PREFIX_PATH:STRING=${CMAKE_CURRENT_BINARY_DIR}/fmt.exploded)

# Spdlog v1.8.5 and older only allows the setting of custom levels via a
# compile/pre-processor definition. Historically we accomplished this using
# target_compile_definitions but I think add_compile_definitions works too.
# Unfortunately, ExternalProject doesn't appear to have a method of doing this.
# We should be able to accomplish this by adding the definition to CXX_FLAGS but
# using double quotation marks in the definition makes this an escaping
# nightmare that I don't particularly want to solve. We can tackle this in a
# more creative way though. We could:
# 1) Use a PATCH_COMMAND to modify "include/spdlog/tweakme.h" to add the
#    definition.
# 2) Use a PATCH_COMMAND to modify CMakeLists.txt to add the definition (but
#    it feels much more reasonable to change the file made to be tweaked)
# 3) Create a CMake wrapper which builds spdlog after adding the compile
#    definition
#
# 1 feels like the most reasonable solution here as we're using a command
# intended for this and a file intended to be modified.
#
# In the future when we upgrade spdlog to the next version we should be able
# to supply custom log levels via cmake cache variables (the code looks to have
# been changed already but isn't in a released version). We can then remove the
# PATCH_COMMAND and our version of tweakme.h.

# Note - it would be nice to be able to build and run spdlog's unit tests
# (SPDLOG_BUILD_TESTS=ON) to verify the build , however as we change the names
# of the log levels, a number of tests fail as they expect the default level
# names.
ExternalProject_Add(spdlog
        GIT_REPOSITORY ${_git_repo}
        GIT_TAG ${_git_rev}
        INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install

        PATCH_COMMAND git apply ${CMAKE_CURRENT_SOURCE_DIR}/custom_level_names.patch
        CMAKE_CACHE_ARGS ${cache_args}
        CMAKE_ARGS -D CMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>

        BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism})

# Only build the TSan package on linux and macos platforms to save
# time.
if (${PLATFORM} STREQUAL "linux" OR ${PLATFORM} MATCHES "macos")
    ExternalProject_Add(spdlog_tsan
            GIT_REPOSITORY ${_git_repo}
            GIT_TAG ${_git_rev}
            INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install/tsan_root

            PATCH_COMMAND git apply ${CMAKE_CURRENT_SOURCE_DIR}/custom_level_names.patch
            CMAKE_CACHE_ARGS ${cache_args}
                "-DCMAKE_C_COMPILER:STRING=clang"
                "-DCMAKE_CXX_COMPILER:STRING=clang++"
                "-DCMAKE_CXX_FLAGS:STRING=-fsanitize=thread"
            CMAKE_ARGS -D CMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>

            BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism})

    ExternalProject_Add_StepDependencies(spdlog download spdlog_tsan)
endif()

# Additionally build a Debug variant on Windows, as for a debug build of
# CB Server we need all dependancies _also_ linked against Debug CRT.
if (WIN32)
    ExternalProject_Add(spdlog_WinDebugCRT
            GIT_REPOSITORY ${_git_repo}
            GIT_TAG ${_git_rev}
            PATCH_COMMAND git apply ${CMAKE_CURRENT_SOURCE_DIR}/custom_level_names.patch
            CMAKE_CACHE_ARGS ${cache_args}
            CMAKE_ARGS -D CMAKE_BUILD_TYPE=Debug

            BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}

            INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install)
    ExternalProject_Add_StepDependencies(spdlog download spdlog_WinDebugCRT)
endif()

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
