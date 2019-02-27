if (NOT DEFINED OPENTRACING_FOUND)
    include(PlatformIntrospection)

    cb_get_supported_platform(_supported_platform)
    if (_supported_platform)
        set(_opentracing_no_default_path NO_DEFAULT_PATH)
    endif ()

    set(_opentracing_exploded ${CMAKE_BINARY_DIR}/tlm/deps/opentracing-cpp.exploded)
    set(_opentracing_library_dir ${CMAKE_INSTALL_PREFIX})

    find_path(OPENTRACING_INCLUDE_DIR opentracing/version.h
              HINTS ${_opentracing_exploded}/include
              ${_opentracing_no_default_path})

    find_library(OPENTRACING_LIBRARIES
                 NAMES opentracing
                 HINTS ${_opentracing_library_dir}/lib
                 ${_opentracing_no_default_path})

    if (OPENTRACING_INCLUDE_DIR AND OPENTRACING_LIBRARIES)
        message(STATUS "Found OpenTracing headers in: ${OPENTRACING_INCLUDE_DIR}")
        message(STATUS "                            : ${OPENTRACING_LIBRARIES}")
        set(OPENTRACING_FOUND true CACHE BOOL "Found OpenTracing" FORCE)
    else ()
        set(OPENTRACING_FOUND false CACHE BOOL "Found OpenTracing" FORCE)
    endif ()
endif (NOT DEFINED OPENTRACING_FOUND)
