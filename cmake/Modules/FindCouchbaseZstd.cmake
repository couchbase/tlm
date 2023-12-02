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

    if (NOT DEFINED _zstd_cpp_include_dir)
        set(_zstd_cpp_include_dir ${CMAKE_BINARY_DIR}/tlm/deps/zstd-cpp.exploded/include)
    endif ()
    if (NOT DEFINED _zstd_cpp_library_dir)
        set(_zstd_cpp_library_dir ${CMAKE_BINARY_DIR}/tlm/deps/zstd-cpp.exploded/lib)
    endif ()

    find_path(ZSTD_CPP_INCLUDE_DIR
              NAMES zstd.h
              PATHS
              ${_zstd_cpp_include_dir}
              ${_zstd_cpp_rocksdb_include_dir}
              ${_zstd_cpp_no_default_path})

    find_library(ZSTD_CPP_LIBRARIES
                 NAMES zstd
                 PATHS
                 ${_zstd_cpp_library_dir}
                 ${_zstd_cpp_rocksdb_library_dir}
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

IF (ZSTD_CPP_FOUND AND NOT TARGET Zstd::zstd)
    # Pretend we're using Modern CMake to find this thing.
    add_library(Zstd::zstd STATIC IMPORTED)
    set_target_properties(Zstd::zstd
        PROPERTIES
        IMPORTED_LOCATION ${ZSTD_CPP_LIBRARIES})
    target_include_directories(Zstd::zstd INTERFACE
        ${ZSTD_CPP_INCLUDE_DIR})
ENDIF ()