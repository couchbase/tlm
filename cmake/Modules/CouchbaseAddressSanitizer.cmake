# Support for building with AddressSanitizer (asan) -
# https://github.com/google/sanitizers/wiki/AddressSanitizer
#
# Usage:
# The variable CB_ADDRESSSANITIZER is used to enable ASAN, which
# accepts the following values:
#   0: Disabled.
#   1: Global - All targets will have ASan enabled on them.
#   2: Specific - Only targets which explicitly enable ASan, via the
#      add_sanitizers() macro will have ASan enabled.

INCLUDE(CheckCCompilerFlag)
INCLUDE(CheckCXXCompilerFlag)
INCLUDE(CMakePushCheckState)

OPTION(CB_ADDRESSSANITIZER "Enable AddressSanitizer memory error detector."
       0)

IF (CB_ADDRESSSANITIZER)

    CMAKE_PUSH_CHECK_STATE(RESET)
    SET(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address") # Also needs to be a link flag for test to pass
    CHECK_C_COMPILER_FLAG("-fsanitize=address" HAVE_FLAG_SANITIZE_ADDRESS_C)
    CHECK_CXX_COMPILER_FLAG("-fsanitize=address" HAVE_FLAG_SANITIZE_ADDRESS_CXX)
    CMAKE_POP_CHECK_STATE()

    IF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
      # Clang requires an external symbolizer program.
      FIND_PROGRAM(LLVM_SYMBOLIZER
                   NAMES llvm-symbolizer
                         llvm-symbolizer-3.8
                         llvm-symbolizer-3.7
                         llvm-symbolizer-3.6)

      IF(NOT LLVM_SYMBOLIZER)
        MESSAGE(WARNING "AddressSanitizer failed to locate an llvm-symbolizer program. Stack traces may lack symbols.")
      ENDIF()
    ENDIF()

    IF(HAVE_FLAG_SANITIZE_ADDRESS_C AND HAVE_FLAG_SANITIZE_ADDRESS_CXX)
        # Have AddressSanitizer for C & C++; enable as per the user's selection.

        # Need -fno-omit-frame-pointer to allow the backtraces to be symbolified.
        SET(ADDRESS_SANITIZER_FLAG -fsanitize=address -fno-omit-frame-pointer)
        SET(ADDRESS_SANITIZER_LDFLAGS -fsanitize=address)

        # TC/jemalloc cause issues with AddressSanitizer - force
        # the use of the system allocator.
        SET(COUCHBASE_MEMORY_ALLOCATOR system CACHE STRING "Memory allocator to use")

        # Configure CTest's MemCheck to AddressSanitizer.
        SET(MEMORYCHECK_TYPE AddressSanitizer)

        if(NOT CB_ADDRESSSANITIZER EQUAL 2)
            # Enable globally
            ADD_COMPILE_OPTIONS(${ADDRESS_SANITIZER_FLAG})
            ADD_LINK_OPTIONS(${ADDRESS_SANITIZER_LDFLAGS})

            use_rpath_for_sanitizers()

            ADD_DEFINITIONS(-DADDRESS_SANITIZER)

            # Need to install libasan to be able to run sanitized
            # binaries on a machine different to the build machine
            # (for example for RPM sanitized packages).

            if (UNIX AND NOT APPLE AND NOT "${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
                # Try to detect the ASan runtime shared library version to use.
                # Note: Clang statically links the ASan runtime so we skip this
                # for Clang.
                # GCC 7.3 CV currently uses libasan.so.4, but out of the box
                # Ubuntu 20.04 wants to use GCC 9.3 and wants libasan.so.5.
                # GCC 10.2 uses libasan.so.6
                install_sanitizer_library(ASan "libasan.so.6;libasan.so.5;libasan.so.4" "${ADDRESS_SANITIZER_FLAG}" ${CMAKE_INSTALL_PREFIX}/lib)
            endif ()
        endif ()

        MESSAGE(STATUS "AddressSanitizer enabled (mode ${CB_ADDRESSSANITIZER})")
    ELSE()
        MESSAGE(FATAL_ERROR "CB_ADDRESSSANITIZER enabled but compiler doesn't support AddressSanitizer - cannot continue.")
    ENDIF()
ENDIF()

# Enable AddressSanitizer for specific target. No-op if
# CB_ADDRESSSANITIZER is not set to 2 (target-specific mode).
# Typically used via add_sanitizers()
function(add_sanitize_memory TARGET)
    if (NOT CB_ADDRESSSANITIZER EQUAL 2)
        return()
    endif ()

    set_property(TARGET ${TARGET} APPEND_STRING
        PROPERTY COMPILE_FLAGS " ${ADDRESS_SANITIZER_FLAG}")
    set_property(TARGET ${TARGET} APPEND_STRING
        PROPERTY LINK_FLAGS " ${ADDRESS_SANITIZER_LDFLAGS}")
endfunction()

# Disable AddressSanitizer for specific target. No-op if
# CB_ADDRESSSANITIZER is not enabled.
# Typically used via remove_sanitizers()
function(remove_sanitize_memory TARGET)
    if (NOT CB_ADDRESSSANITIZER)
        return()
    endif ()

    remove_from_property(${TARGET} COMPILE_OPTIONS ${ADDRESS_SANITIZER_FLAG})
    remove_from_property(${TARGET} LINK_OPTIONS ${ADDRESS_SANITIZER_LDFLAGS})
endfunction()

# Define environment variables to set for tests running under
# ASan. Typically used by top-level CouchbaseSanitizers.cmake.
function(add_sanitizer_env_vars_memory TARGET)
    if(NOT CB_ADDRESSSANITIZER)
        return()
    endif()

    set(lsan_options "suppressions=${CMAKE_SOURCE_DIR}/tlm/lsan.suppressions")
    set_property(TEST ${TARGET} APPEND PROPERTY ENVIRONMENT
                 "ASAN_SYMBOLIZER_PATH=${LLVM_SYMBOLIZER}"
                 "LSAN_OPTIONS=${lsan_options}")
endfunction()
