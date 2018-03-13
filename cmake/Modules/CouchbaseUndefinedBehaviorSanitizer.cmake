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

    CMAKE_PUSH_CHECK_STATE(RESET)
    SET(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined") # Also needs to be a link flag for test to pass
    CHECK_C_COMPILER_FLAG("-fsanitize=undefined" HAVE_FLAG_SANITIZE_UNDEFINED_C)
    CHECK_CXX_COMPILER_FLAG("-fsanitize=undefined" HAVE_FLAG_SANITIZE_UNDEFINED_CXX)
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

        SET(UNDEFINED_SANITIZER_FLAG "-fsanitize=undefined -fno-sanitize=alignment")

        # Configure CTest's MemCheck mode.
        SET(MEMORYCHECK_TYPE UndefinedBehaviorSanitizer)

        if(CB_UNDEFINEDSANITIZER EQUAL 1)
            # Enable globally

            # Need -fno-omit-frame-pointer to allow the backtraces to be symbolified.
            SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${UNDEFINED_SANITIZER_FLAG} -fno-omit-frame-pointer")
            SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${UNDEFINED_SANITIZER_FLAG} -fno-omit-frame-pointer")
            SET(CMAKE_CGO_LDFLAGS "${CMAKE_CGO_LDFLAGS} ${UNDEFINED_SANITIZER_FLAG}")
	    ADD_DEFINITIONS(-DUNDEFINED_SANITIZER)
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
        PROPERTY COMPILE_FLAGS " ${UNDEFINED_SANITIZER_FLAG} -fno-omit-frame-pointer")
    set_property(TARGET ${TARGET} APPEND_STRING
        PROPERTY LINK_FLAGS " ${UNDEFINED_SANITIZER_FLAG}")
endfunction()
