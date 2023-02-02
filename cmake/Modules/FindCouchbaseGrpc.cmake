# Locate the gRPC library
# This module defines
#  GRPC_FOUND
#  GRPC_LIBRARIES, library path and libs
#  GRPC_INCLUDE_DIR, where to find the headers
#  PROTOC, protoc compiler
#  GRPC_CPP_PLUGIN_EXE, plugin for generating C++ gRPC client and server
#  PROTOC_GEN_GO_EXE, plugin for generating Go gRPC client and server

if (NOT DEFINED GRPC_FOUND)
    include (PlatformIntrospection)
    cb_get_supported_platform (_is_supported_platform)

    if (_is_supported_platform)
        set (_grpc_no_default_path NO_DEFAULT_PATH)
    endif ()

    set (_grpc_exploded ${CMAKE_BINARY_DIR}/tlm/deps/grpc.exploded)
    set (_protoc_gen_go_exploded ${CMAKE_BINARY_DIR}/tlm/deps/protoc-gen-go.exploded)

    find_path (GRPC_INCLUDE_DIR grpc
        HINTS ${_grpc_exploded}/include
        ${_grpc_no_default_path})
    if (NOT GRPC_INCLUDE_DIR)
        message (FATAL_ERROR "Failed to locate gRPC headers")
    endif ()

    find_program(PROTOC protoc
            HINTS ${_grpc_exploded}/bin)
    if (NOT PROTOC)
        message(FATAL_ERROR "Failed to locate protoc")
    endif ()

    find_program(GRPC_CPP_PLUGIN_EXE grpc_cpp_plugin
            HINTS ${_grpc_exploded}/bin)
    if (NOT GRPC_CPP_PLUGIN_EXE)
        message(FATAL_ERROR "Failed to locate grpc_cpp_plugin")
    endif ()

    find_program (PROTOC_GEN_GO_EXE protoc-gen-go
        HINTS ${_protoc_gen_go_exploded}/bin)
    if (NOT PROTOC_GEN_GO_EXE)
        message(FATAL_ERROR "Failed to locate protoc-gen-go")
    endif ()

    find_package (ZLIB REQUIRED)

    if (NOT GRPC_LIBRARIES)
        set (_grpc_libraries
             grpc++
             grpc++_error_details
             grpc++_reflection
             grpc++_unsecure
             grpc_unsecure
             grpc
             address_sorting
             gpr
             cares
             absl_strings
             absl_str_format_internal
             absl_strings_internal
             absl_raw_logging_internal
             absl_throw_delegate
             absl_int128
             absl_log_severity
             absl_bad_optional_access
             absl_spinlock_wait
             absl_base
             upb
             )
        # Additional static libs copied in from the GRPC package build
        # (some have different names on Unix and Windows)
        if (WIN32)
            list (APPEND _grpc_libraries
                  libprotobuf)
        else ()
            list (APPEND _grpc_libraries
                  protobuf)
        endif ()
        foreach (_mylib ${_grpc_libraries})
            unset (_the_lib CACHE)
            find_library (_the_lib
                NAMES ${_mylib}
                HINTS ${_grpc_exploded}/lib
                ${_grpc_no_default_path})
            if (_the_lib)
                list (APPEND _grpc_libs_found ${_the_lib})
            else (_the_lib)
                message (FATAL_ERROR "Can't build Couchbase without ${_mylib}")
            endif (_the_lib)
        endforeach (_mylib)
        set (GRPC_LIBRARIES ${_grpc_libs_found} ${ZLIB_LIBRARIES} ${OPENSSL_LIBRARIES}
             CACHE STRING "gRPC Libraries" FORCE)
    endif (NOT GRPC_LIBRARIES)

    if (GRPC_LIBRARIES)
        message (STATUS "Found gRPC headers in: ${GRPC_INCLUDE_DIR}")
        message (STATUS "            libraries: ${GRPC_LIBRARIES}")
    else (GRPC_LIBRARIES)
        message (FATAL_ERROR "Can't build Couchbase without gRPC")
    endif (GRPC_LIBRARIES)

    set (GRPC_FOUND true CACHE BOOL "Found gRPC" FORCE)
    mark_as_advanced (GRPC_FOUND GRPC_INCLUDE_DIR GRPC_LIBRARIES PROTOC GRPC_CPP_PLUGIN_EXE PROTOC_GEN_GO_EXE)
endif (NOT DEFINED GRPC_FOUND)