# Locate zstd-cpp
# This module defines
#  ZSTD_CPP_LIBRARIES, Library path and libs
#  ZSTD_CPP_INCLUDE_DIR, where to find the headers
#  ZSTD_CPP_FOUND, whether it was found or not
if (NOT DEFINED ZSTD_CPP_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_is_supported_platform)
    if (_is_supported_platform)
        set(_zstd_cpp_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_zstd_cpp_include_dir ${CMAKE_BINARY_DIR}/tlm/deps/zstd-cpp.exploded/include)
    set(_zstd_cpp_library_dir ${CMAKE_INSTALL_PREFIX}/lib)

    find_path(ZSTD_CPP_INCLUDE_DIR zstd.h
              HINTS ${_zstd_cpp_include_dir}
              ${_zstd_cpp_no_default_path})

    find_library(ZSTD_CPP_LIBRARIES
                 NAMES zstd
                 HINTS ${_zstd_cpp_library_dir}
                 ${_zstd_cpp_no_default_path})

    if (ZSTD_CPP_INCLUDE_DIR AND ZSTD_CPP_LIBRARIES)
        message(STATUS "Found zstd-cpp headers in: ${ZSTD_CPP_INCLUDE_DIR}")
        message(STATUS "Found zstd-cpp library   : ${ZSTD_CPP_LIBRARIES}")
        set(ZSTD_CPP_FOUND true CACHE BOOL "Found zstd-cpp" FORCE)
    else ()
        message(STATUS "Did not find zstd-cpp")
        set(ZSTD_CPP_FOUND false CACHE BOOL "Found zstd-cpp" FORCE)
    endif ()
endif (NOT DEFINED ZSTD_CPP_FOUND)
