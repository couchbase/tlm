# Support for building with AddressSanitizer (asan) -
# https://github.com/google/sanitizers/wiki/AddressSanitizer

INCLUDE(CheckCCompilerFlag)
INCLUDE(CheckCXXCompilerFlag)
INCLUDE(CMakePushCheckState)

OPTION(CB_ADDRESSSANITIZER "Enable AddressSanitizer memory error detector."
       OFF)

IF (CB_ADDRESSSANITIZER)

    # AddressSanitizer doesn't appear to work correctly on a Debug build :(
    IF ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        MESSAGE(FATAL_ERROR "CB_ADDRESSSANITIZER enabled but AddressSanitizer "
                            "is incompatible with CMAKE_BUILD_TYPE==Debug. "
                            "Change build type RelWithDebInfo or similar to "
                            "use AddressSanitizer. Cannot continue.")
    ENDIF ()

    CMAKE_PUSH_CHECK_STATE(RESET)
    SET(CMAKE_REQUIRED_FLAGS "-fsanitize=address") # Also needs to be a link flag for test to pass
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
        SET(ADDRESS_SANITIZER_FLAG "-fsanitize=address")

        # Need -fno-omit-frame-pointer to allow the backtraces to be symbolified.
        SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ADDRESS_SANITIZER_FLAG} -fno-omit-frame-pointer")
        SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ADDRESS_SANITIZER_FLAG} -fno-omit-frame-pointer")
        SET(CMAKE_CGO_LDFLAGS "${CMAKE_CGO_LDFLAGS} ${ADDRESS_SANITIZER_FLAG}")

        # TC/jemalloc cause issues with AddressSanitizer - force
        # the use of the system allocator.
        SET(COUCHBASE_MEMORY_ALLOCATOR system CACHE STRING "Memory allocator to use")

        # Configure CTest's MemCheck to AddressSanitizer.
        SET(MEMORYCHECK_TYPE AddressSanitizer)

        ADD_DEFINITIONS(-DADDRESS_SANITIZER)

        # Override the normal ADD_TEST macro to set the ASAN_OPTIONS
        # environment variable - this allows us to specify the
        # suppressions file to use.
        FUNCTION(ADD_TEST name)
            IF(${ARGV0} STREQUAL "NAME")
               SET(_name ${ARGV1})
            ELSE()
               SET(_name ${ARGV0})
            ENDIF()
            _ADD_TEST(${ARGV})
            SET_TESTS_PROPERTIES(${_name} PROPERTIES ENVIRONMENT
                                 "ASAN_SYMBOLIZER_PATH=${LLVM_SYMBOLIZER}")
        ENDFUNCTION()

        MESSAGE(STATUS "AddressSanitizer enabled.")
    ELSE()
        MESSAGE(FATAL_ERROR "CB_ADDRESSSANITIZER enabled but compiler doesn't support AddressSanitizer - cannot continue.")
    ENDIF()
ENDIF()

