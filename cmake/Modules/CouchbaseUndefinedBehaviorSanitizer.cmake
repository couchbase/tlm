# Support for building with UndefinedBehaviorSanitizer (ubsan) -
# https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html
#
# Usage:
# The variable CB_UNDEFINEDSANITIZER is used to enable UBSAN, which
# accepts the following values:
#   0: Disabled.
#   1: Global - All targets will have UBSan enabled on them.
#   2: Specific - Only targets which explicitly enable UBSan, via the
#      add_sanitizers() macro will have UBSan enabled.

INCLUDE(CheckCCompilerFlag)
INCLUDE(CheckCXXCompilerFlag)
INCLUDE(CMakePushCheckState)

OPTION(CB_UNDEFINEDSANITIZER "Enable UndefinedBehaviorSanitizer memory error detector."
       0)

IF (CB_UNDEFINEDSANITIZER GREATER 0)

    SET(UNDEFINED_SANITIZER_FLAG -fsanitize=undefined -fno-sanitize=alignment -fno-sanitize-recover=all -fno-sanitize=float-divide-by-zero)
    # Need -fno-omit-frame-pointer to allow the backtraces to be symbolified.
    LIST(APPEND UNDEFINED_SANITIZER_FLAG -fno-omit-frame-pointer)
    # UBSan makes heavy use of RTTI to verify the type of objects
    # match the pointer/reference they are accessed through at
    # runtime. This requires typeinfo for essentially all types
    # involved in static_cast<> / reinterpret_cast<>. To simplify
    # providing this; change the default symbol visiibility to
    # default (all symbols visible).
    LIST(APPEND UNDEFINED_SANITIZER_FLAG -fvisibility=default)

    SET(UNDEFINED_SANITIZER_LDFLAGS -fsanitize=undefined)

    CMAKE_PUSH_CHECK_STATE(RESET)
    # Pass the -fsanitize sub-options via CMAKE_REQUIRED_FLAGS - keeps
    # the output of CHECK_{C,CXX}_COMPILER_FLAG() clean (it logs the
    # flag being tested).
    SET(CMAKE_REQUIRED_FLAGS ${UNDEFINED_SANITIZER_FLAGS})
    SET(CMAKE_REQUIRED_LINK_OPTIONS ${UNDEFINED_SANITIZER_LDFLAGS}) # Also needs to be a link flag for test to pass
    CHECK_C_COMPILER_FLAG(-fsanitize=undefined HAVE_FLAG_SANITIZE_UNDEFINED_C)
    CHECK_CXX_COMPILER_FLAG(-fsanitize=undefined HAVE_FLAG_SANITIZE_UNDEFINED_CXX)
    CMAKE_POP_CHECK_STATE()

    IF ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
      # Clang requires an external symbolizer program.
      FIND_PROGRAM(LLVM_SYMBOLIZER
                   NAMES llvm-symbolizer
                         llvm-symbolizer-3.8
                         llvm-symbolizer-3.7
                         llvm-symbolizer-3.6)

      IF(NOT LLVM_SYMBOLIZER)
        MESSAGE(WARNING "UndefinedBehaviorSanitizer failed to locate an llvm-symbolizer program. Stack traces may lack symbols.")
      ENDIF()
    ENDIF()

    IF(HAVE_FLAG_SANITIZE_UNDEFINED_C AND HAVE_FLAG_SANITIZE_UNDEFINED_CXX)
        # Have UndefinedBehaviorSanitizer for C & C++; enable as per the user's selection.

        # Configure CTest's MemCheck mode.
        SET(MEMORYCHECK_TYPE UndefinedBehaviorSanitizer)

        if(CB_UNDEFINEDSANITIZER EQUAL 1)
            # Enable globally
            ADD_COMPILE_OPTIONS(${UNDEFINED_SANITIZER_FLAG})
            ADD_LINK_OPTIONS(${UNDEFINED_SANITIZER_LDFLAGS})

	    ADD_DEFINITIONS(-DUNDEFINED_SANITIZER)

            if (UNIX AND NOT APPLE AND NOT "${CMAKE_C_COMPILER_ID}" STREQUAL "Clang")
                # Need to install libubsan to be able to run sanitized
                # binaries on a machine different to the build machine
                # (for example for RPM sanitized packages).
                # Note: Clang statically links the UBSan runtime so we skip this
                # for Clang.
                install_sanitizer_library(UBSan "libubsan.so.1;libubsan.so.0" "${UNDEFINED_SANITIZER_FLAG}" ${CMAKE_INSTALL_PREFIX}/lib)
            endif()
	endif()

        MESSAGE(STATUS "UndefinedBehaviorSanitizer enabled (mode ${CB_UNDEFINEDSANITIZER})")
    ELSE()
        MESSAGE(FATAL_ERROR "CB_UNDEFINEDSANITIZER enabled but compiler doesn't support UBSan - cannot continue.")
    ENDIF()
ENDIF()

# Enable UBSAN for specific target. No-op if
# CB_UNDEFINEDSANITIZER is not set to 2 (target-specific mode).
# Typically used via add_sanitizers()
function(add_sanitize_undefined TARGET)
    if (NOT CB_UNDEFINEDSANITIZER EQUAL 2)
        return()
    endif ()

    set_property(TARGET ${TARGET} APPEND_STRING
        PROPERTY COMPILE_FLAGS " ${UNDEFINED_SANITIZER_FLAG}")
    set_property(TARGET ${TARGET} APPEND_STRING
        PROPERTY LINK_FLAGS " ${UNDEFINED_SANITIZER_LDFLAGS}")
endfunction()

# Disable UBSAN for specific target. No-op if
# CB_UNDEFINEDSANITIZER is not enabled.
# Typically used via remove_sanitizers()
function(remove_sanitize_undefined TARGET)
    if (NOT CB_UNDEFINEDSANITIZER)
        return()
    endif ()
    remove_from_property(${TARGET} COMPILE_OPTIONS ${UNDEFINED_SANITIZER_FLAG})
    remove_from_property(${TARGET} LINK_OPTIONS ${UNDEFINED_SANITIZER_LDFLAGS})
endfunction()

# Define environment variables to set for tests running under
# UBSan. Typically used by top-level CouchbaseSanitizers.cmake.
function(add_sanitizer_env_vars_undefined TARGET)
    if(NOT CB_UNDEFINEDSANITIZER)
        return()
    endif()

    set(ubsan_options "suppressions=${CMAKE_SOURCE_DIR}/tlm/ubsan.suppressions print_stacktrace=1")

    # Prepend to any existing UBSAN_OPTION env var, to allow drivers
    # of the build (like Jenkins jobs) to override options set here -
    # for example logging output to files instead of stderr.
    set(ubsan_options "${ubsan_options} $ENV{UBSAN_OPTIONS}")

    set_property(TEST ${TARGET} APPEND PROPERTY ENVIRONMENT
                 "UBSAN_OPTIONS=${ubsan_options}")
endfunction()
