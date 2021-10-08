# Support for building with ThreadSanitizer (tsan) -
# https://code.google.com/p/thread-sanitizer/

INCLUDE(CheckCCompilerFlag)
INCLUDE(CheckCXXCompilerFlag)
INCLUDE(CMakePushCheckState)

OPTION(CB_THREADSANITIZER "Enable ThreadSanitizer data race detector."
       OFF)

IF (CB_THREADSANITIZER)
    CMAKE_PUSH_CHECK_STATE(RESET)
    SET(CMAKE_REQUIRED_FLAGS "-fsanitize=thread") # Also needs to be a link flag for test to pass
    CHECK_C_COMPILER_FLAG("-fsanitize=thread" HAVE_FLAG_SANITIZE_THREAD_C)
    CHECK_CXX_COMPILER_FLAG("-fsanitize=thread" HAVE_FLAG_SANITIZE_THREAD_CXX)
    CMAKE_POP_CHECK_STATE()

    IF(HAVE_FLAG_SANITIZE_THREAD_C AND HAVE_FLAG_SANITIZE_THREAD_CXX)
        SET(THREAD_SANITIZER_FLAG "-fsanitize=thread")
        SET(THREAD_SANITIZER_LDFLAGS "-fsanitize=thread")

        # MB-41896: Clang links to the TSan runtime library statically
        # by default. This is problematic as we can have multiple
        # different libraries linked into a final executable, and hence
        # end up with multiple copies of the static runtime library.
        # This causes incorrect behavour when TSan runtime tries to
        # track locks.
        # Link to the shared runtime library to avoid this.
        # (Note: AppleClang defaults to shared linking so doesn't have this problem).
        IF(CMAKE_C_COMPILER_ID STREQUAL "Clang")
            # Append extra flags to THREAD_SANITIZER_FLAG, so they can
            # be correctly removed for unsanitized targets - see
            # remove_sanitize_thread() below.
            LIST(APPEND THREAD_SANITIZER_LDFLAGS -shared-libsan)
            LIST(APPEND THREAD_SANITIZER_LDFLAGS -ltsan)

            LINK_LIBRARIES(tsan)
        ENDIF()

        ADD_COMPILE_OPTIONS(${THREAD_SANITIZER_FLAG})
        ADD_LINK_OPTIONS(${THREAD_SANITIZER_LDFLAGS})

        # Ensure TSan flags are used for cgo compile and link, so Go
        # programs linking to TSan-enabled C/C++ libraries have the
        # correct tsan runtime library available.
        SET(CMAKE_CGO_CFLAGS "${CMAKE_CGO_CFLAGS} ${THREAD_SANITIZER_FLAG}")
        STRING(REPLACE ";" " " tsan_ldflags_list "${THREAD_SANITIZER_LDFLAGS}")
        SET(CMAKE_CGO_LDFLAGS "${CMAKE_CGO_LDFLAGS} ${tsan_ldflags_list}")

        use_rpath_for_sanitizers()

        # TC/jemalloc are incompatible with ThreadSanitizer - force
        # the use of the system allocator.
        SET(COUCHBASE_MEMORY_ALLOCATOR system CACHE STRING "Memory allocator to use")

        # Configure CTest's MemCheck to ThreadSanitizer.
        SET(MEMORYCHECK_TYPE ThreadSanitizer)

        ADD_DEFINITIONS(-DTHREAD_SANITIZER)

        if (NOT CMAKE_C_COMPILER_ID STREQUAL "AppleClang")
            # Need to install libtsan to be able to run sanitized
            # binaries on a machine different to the build machine
            # (for example for RPM sanitized packages).
            # library).
            install_sanitizer_library(TSan
                                      libtsan.so.0
                                      "${THREAD_SANITIZER_FLAG};${THREAD_SANITIZER_LDFLAGS}"
                                      ${CMAKE_INSTALL_PREFIX}/lib)
        endif()

        SET(THREAD_SANITIZER_TEST_ENV "TSAN_OPTIONS=suppressions=${CMAKE_SOURCE_DIR}/tlm/tsan.suppressions\ second_deadlock_stack=1\ history_size=7")
        # On some platforms (at least macOS Mojave), mutex deadlocking is
        # not enabled by default.
        SET(THREAD_SANITIZER_TEST_ENV "${THREAD_SANITIZER_TEST_ENV}\ detect_deadlocks=1")

        # Override the normal ADD_TEST macro to set the TSAN_OPTIONS
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
                                 ${THREAD_SANITIZER_TEST_ENV})
        ENDFUNCTION()

        MESSAGE(STATUS "ThreadSanitizer enabled - forcing use of 'system' memory allocator.")
    ELSE()
        MESSAGE(FATAL_ERROR "CB_THREADSANITIZER enabled but compiler doesn't support ThreadSanitizer - cannot continue.")
    ENDIF()
ENDIF()

# Disable ThreadSanitizer for specific target. No-op if
# CB_THREADSANITIZER is not enabled.
# Typically used via remove_sanitizers()
function(remove_sanitize_thread TARGET)
    if (NOT CB_THREADSANITIZER)
        return()
    endif ()
    remove_from_property(${TARGET} COMPILE_OPTIONS ${THREAD_SANITIZER_FLAG})
    remove_from_property(${TARGET}
        LINK_OPTIONS ${THREAD_SANITIZER_FLAG} ${THREAD_SANITIZER_LDFLAGS})

    # Remove any explicitly added TSan runtime libraries - see
    # LINK_LIBRARIES(tsan) call above.
    if(CMAKE_C_COMPILER_ID STREQUAL "Clang" OR CMAKE_C_COMPILER_ID STREQUAL "AppleClang")
        remove_from_property(${TARGET} LINK_LIBRARIES tsan)
        remove_from_property(${TARGET} INTERFACE_LINK_LIBRARIES tsan)
    endif()
endfunction()
