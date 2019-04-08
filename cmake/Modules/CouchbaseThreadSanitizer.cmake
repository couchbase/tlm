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

        SET(THREAD_SANITIZER_FLAG_DISABLE "-fno-sanitize=address")

        SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${THREAD_SANITIZER_FLAG}")
        SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${THREAD_SANITIZER_FLAG}")
        SET(CMAKE_CGO_LDFLAGS "${CMAKE_CGO_LDFLAGS} ${THREAD_SANITIZER_FLAG}")

        # Workaround a problem with ThreadSanitizer, dlopen and RPATH:
        #
        # Background:
        #
        # Couchbase server (e.g. engine_testapp) makes use of dlopen()
        # to load the engine and the testsuite. The runtime linker
        # determines the search path to use by looking at the values
        # of RPATH and RUNPATH in the executable (e.g. engine_testapp)
        #
        # - RUNPATH is the "older" property, it is used by the
        #   executable and _any other libraries the executable loads_
        #   to locate dlopen()ed files.
        #
        # - RPATH is the "newer" (and more secure) property - is is
        #   only used when the executable itself loads a library -
        #   i.e. it isn't inherited by opened libraries like RUNPATH.
        #
        # (Summary, see `man dlopen` for full details of search
        # order).
        #
        # CMake will set RPATH / RUNPATH (via linker arg -Wl) to the
        # set of directories where all dependancies reside - and this
        # is necessary for engine_testapp to load the engine and
        # testsuite.
        #
        # Problem:
        #
        # When running under ThreadSanitizer, TSan intercepts dlopen()
        # and related functions, which results in the dlopen()
        # appearing to come from libtsan.so. Given the above, this
        # means that if RPATH is used, then the dlopen() for engine
        # and testsuite fails, as libtsan doesn't have the path to
        # ep.so for example embedded in it, and with RPATH the paths
        # arn't inherited from the main executable.
        #
        # Newer versions of ld (at least Ubuntu 17.10) now use RPATH
        # by default (as it is more secure), which means that we hit
        # the above problem. To avoid this, use RUNPATH instead when
        # running on a system which recognises the flag.
        CHECK_CXX_COMPILER_FLAG("-Wl,--disable-new-dtags" COMPILER_SUPPORTS_DISABLE_NEW_DTAGS)
        IF(COMPILER_SUPPORTS_DISABLE_NEW_DTAGS)
          SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--disable-new-dtags")
          SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--disable-new-dtags")
        ENDIF()

        # TC/jemalloc are incompatible with ThreadSanitizer - force
        # the use of the system allocator.
        SET(COUCHBASE_MEMORY_ALLOCATOR system CACHE STRING "Memory allocator to use")

        # Configure CTest's MemCheck to ThreadSanitizer.
        SET(MEMORYCHECK_TYPE ThreadSanitizer)

        ADD_DEFINITIONS(-DTHREAD_SANITIZER)

        # Need to install libtsan to be able to run sanitized
        # binaries on a machine different to the build machine
        # (for example for RPM sanitized packages).
        find_sanitizer_library(tsan_lib libtsan.so.0)
        if (tsan_lib)
            message(STATUS "Found libtsan at: ${tsan_lib}")
            install(FILES ${tsan_lib} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
            if (IS_SYMLINK ${tsan_lib})
                # Often a shared library is actually a symlink to a versioned file - e.g.
                # libtsan.so.1 -> libtsan.so.1.0.0
                # In which case we also need to install the real file.
                get_filename_component(tsan_lib_realpath ${tsan_lib} REALPATH)
                install(FILES ${tsan_lib_realpath} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
            endif ()
        else ()
            # Only raise error if building for linux
            if (UNIX AND NOT APPLE)
                message(FATAL_ERROR "TSan library not found.")
            endif ()
        endif ()

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

            SET(tsan_options "suppressions=${CMAKE_SOURCE_DIR}/tlm/tsan.suppressions second_deadlock_stack=1 history_size=7")
            # On some platforms (at least macOS Mojave), mutex deadlocking is
            # not enabled by default.
            SET(tsan_options "${tsan_options} detect_deadlocks=1")
            SET_TESTS_PROPERTIES(${_name} PROPERTIES ENVIRONMENT
                                 "TSAN_OPTIONS=${tsan_options}")
        ENDFUNCTION()

        MESSAGE(STATUS "ThreadSanitizer enabled - forcing use of 'system' memory allocator.")
    ELSE()
        MESSAGE(FATAL_ERROR "CB_THREADSANITIZER enabled but compiler doesn't support ThreadSanitizer - cannot continue.")
    ENDIF()
ENDIF()

