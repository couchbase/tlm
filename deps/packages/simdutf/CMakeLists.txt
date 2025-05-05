include(ExternalProject)
include(CheckCXXCompilerFlag)

_DETERMINE_CPU_COUNT(_parallelism)

if (UNIX)
    set(cxx_flags "-fPIC -fvisibility=hidden")
    check_cxx_compiler_flag(-march=x86-64-v3 HAVE_MARCH_X86_64_V3)
    if (HAVE_MARCH_X86_64_V3)
        message(STATUS "Building with -march=x86-64-v3")
        set(cxx_flags "${cxx_flags} -march=x86-64-v3")
    else()
        _DETERMINE_ARCH(HOST_ARCH)
        if (${HOST_ARCH} STREQUAL x86_64)
            message(FATAL_ERROR "Can't build with g++ on x86_64 without support for -march=x86-64-v3")
        endif()
    endif()
    list(APPEND cache_args ${common_cmake_cache_args})
    list(APPEND cache_args -DCMAKE_CXX_FLAGS:STRING=${cxx_flags})
endif()

ExternalProject_Add(simdutf
    GIT_REPOSITORY ${_git_repo}
    GIT_TAG v${_git_rev}

    CMAKE_CACHE_ARGS ${cache_args}
    CMAKE_ARGS -D CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/install
               -D CMAKE_BUILD_TYPE=RelWithDebInfo
               -D CMAKE_INSTALL_LIBDIR=lib
               -D CMAKE_CXX_STANDARD=17
               -D SIMDUTF_BENCHMARKS=OFF
               -D SIMDUTF_TESTS=ON
               -D SIMDUTF_ICONV=OFF
               -D SIMDUTF_TOOLS=OFF

    BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${_parallelism}

    TEST_BEFORE_INSTALL 1

    INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/install
    INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
            COMMAND ${CMAKE_COMMAND} -E remove_directory <INSTALL_DIR>/lib/pkgconfig)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
