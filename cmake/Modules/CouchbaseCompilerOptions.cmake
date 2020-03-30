include(CheckIncludeFileCXX)

# Create a list of all of the directories we would like to be treated
# as system headers (and not report compiler warnings from (if the
# compiler supports it). This is used by the compiler-specific Options
# cmake files below.
#
# Note that as a side-effect this will change the compiler
# search order - non-system paths (-I) are searched before
# system paths.
# Therefore if a header file exists both in a standard
# system location (e.g. /usr/local/include) and in one of
# our paths then adding to CB_SYSTEM_HEADER_DIRS may
# result in the compiler picking up the wrong version.
# As a consequence of this we only add headers which
# (1) have known warning issues and (2) are unlikely
# to exist in a normal system location.

# Explicitly add Google Breakpad as it's headers have
# many warnings :(
if (IS_DIRECTORY "${BREAKPAD_INCLUDE_DIR}")
    list(APPEND CB_SYSTEM_HEADER_DIRS "${BREAKPAD_INCLUDE_DIR}")
endif (IS_DIRECTORY "${BREAKPAD_INCLUDE_DIR}")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

message(STATUS "C++ compiler version: ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "C++ language version: ${CMAKE_CXX_STANDARD}")

# Verify that compiler actually suppors the main C++17 features used -
# some compilers *couch* AppleClang 9 *couch* claim support C++17 but
# are missing core library features.
CHECK_INCLUDE_FILE_CXX(optional HAVE_OPTIONAL)
if (NOT HAVE_OPTIONAL)
  unset(HAVE_OPTIONAL)
  message(FATAL_ERROR "C++ compiler claims C++17 support but is missing required header <optional>. Check if your compiler (${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}) fully supports C++17.")
endif()
CHECK_INCLUDE_FILE_CXX(variant HAVE_VARIANT)
if (NOT HAVE_VARIANT)
  unset(HAVE_VARIANT)
  message(FATAL_ERROR "C++ compiler claims C++17 support but is missing required header <variant>. Check if your compiler (${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}) fully supports C++17.")
endif()

#
# Set flags for the C and C++ Compiler
#
if ("${CMAKE_C_COMPILER_ID}" STREQUAL "GNU")
    if (NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
        message(WARNING "C compiler identifier: ${CMAKE_C_COMPILER_ID}")
        message(WARNING "C++ compiler identifier: ${CMAKE_CXX_COMPILER_ID}")
        message(FATAL_ERROR "Unsupported configuration. Please use both a GNU C and C++ compiler")
    endif()

    include(CouchbaseGccOptions)
elseif ("${CMAKE_C_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_C_COMPILER_ID}" STREQUAL "AppleClang")
    if (NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" AND NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
        message(WARNING "C compiler identifier: ${CMAKE_C_COMPILER_ID}")
        message(WARNING "C++ compiler identifier: ${CMAKE_CXX_COMPILER_ID}")
        message(FATAL_ERROR "Unsupported configuration. Please use both a GNU C and C++ compiler")
    endif()
    include(CouchbaseClangOptions)
elseif ("${CMAKE_C_COMPILER_ID}" STREQUAL "MSVC")
    if (NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
        message(WARNING "C compiler identifier: ${CMAKE_C_COMPILER_ID}")
        message(WARNING "C++ compiler identifier: ${CMAKE_CXX_COMPILER_ID}")
        message(FATAL_ERROR "Unsupported configuration. Please use both a GNU C and C++ compiler")
    endif()
    include(CouchbaseMsvcOptions)
else ()
    message(FATAL_ERROR "Unsupported C compiler: ${CMAKE_C_COMPILER_ID}")
endif ()

# Add common -D sections
include(CouchbaseDefinitions)

# Setup the RPATH
include(CouchbaseRpath)

# Check function attibute availability
# - warn_used_result
include(CheckCCompilerFlag)
check_c_source_compiles("int main() {
      return 0;
}
int foo() __attribute__((warn_unused_result));" HAVE_ATTR_WARN_UNUSED_RESULT)

# - printf-style format checking
check_c_source_compiles("int main() {
      return 0;
}
int my_printf(const char* fmt, ...) __attribute__((format (printf, 1, 2)));" HAVE_ATTR_FORMAT)

# - noreturn for functions not returning
check_c_source_compiles("int main() {
      return 0;
}
int foo(void) __attribute__((noreturn));" HAVE_ATTR_NORETURN)

# - nonnull parameters that can't be null
check_c_source_compiles("int main() {
      return 0;
}
int foo(void* foo) __attribute__((nonnull(1)));" HAVE_ATTR_NONNULL)

# - deprecated
check_c_source_compiles("int main() {
      return 0;
}
int foo(void* foo) __attribute__((deprecated));" HAVE_ATTR_DEPRECATED)

if (NOT DEFINED COUCHBASE_DISABLE_CCACHE)
    find_program(CCACHE ccache)

    if (CCACHE)
        get_filename_component(_ccache_realpath ${CCACHE} REALPATH)
        get_filename_component(_cc_realpath ${CMAKE_C_COMPILER} REALPATH)

        if (_ccache_realpath STREQUAL _cc_realpath)
            message(STATUS "seems like ccache is already used via masquerading")
        else ()
            message(STATUS "ccache is available as ${CCACHE}, using it")
            set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ${CCACHE})
            set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ${CCACHE})
        endif ()
    endif (CCACHE)
endif (NOT DEFINED COUCHBASE_DISABLE_CCACHE)

# Add variables for our custom 'DebugOptimized' build type.
#
# DebugOptimized is a trade-off between compilation speed and runtime execution
# speed, which aims to strike a balance between:
# - Relatively fast compile times (faster than Release but slower than Debug)
# - Relatively fast runtime speed (slower than Release but faster than Debug)
# - While still preserving the ability to debug the code.
#
# The primary use-case for this build type is automated commit-validation jobs.
# Given commit-validation jobs compile once and run once, we want to be able
# to balanace compile time and execution time of the unit tests:
# Much of the unit test code is expensive to compile with production-level
# optimization, either simply due to its size, or things like GMock / GTest
# template instantiation, so it's undesirable to compile with Release-level
# optimization, however without _any_ optimizations the unit test code can
# take a long time to execute.
set(CMAKE_CXX_FLAGS_DEBUGOPTIMIZED "${CMAKE_CXX_FLAGS_DEBUG} ${CB_CXX_FLAGS_OPTIMIZE_FOR_DEBUG}"
        CACHE
        STRING "Flags used by the C++ compiler during DebugOptimized builds."
        FORCE )
set(CMAKE_C_FLAGS_DEBUGOPTIMIZED "${CMAKE_C_FLAGS_DEBUG} ${CB_CXX_FLAGS_OPTIMIZE_FOR_DEBUG}"
        CACHE
        STRING "Flags used by the C compiler during DebugOptimized builds."
        FORCE )
set(CMAKE_EXE_LINKER_FLAGS_DEBUGOPTIMIZED
        "${CMAKE_EXE_LINKER_FLAGS_DEBUG}" CACHE
        STRING "Flags used for linking binaries during DebugOptimized builds."
        FORCE )
set(CMAKE_SHARED_LINKER_FLAGS_DEBUGOPTIMIZED
        "${CMAKE_SHARED_LINKER_FLAGS_DEBUG}" CACHE
        STRING "Flags used by the shared libraries linker during DebugOptimized builds."
        FORCE )
mark_as_advanced(
        CMAKE_CXX_FLAGS_DEBUGOPTIMIZED
        CMAKE_C_FLAGS_DEBUGOPTIMIZED
        CMAKE_EXE_LINKER_FLAGS_DEBUGOPTIMIZED
        CMAKE_SHARED_LINKER_FLAGS_DEBUGOPTIMIZED )

# Override the normal compile options for a directory and build with
# CB_CXX_FLAGS_OPTIMIZE_FOR_DEBUG if the build type isn't Debug.
function(add_compile_options_disable_optimization)
    if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
        add_compile_options("${CB_CXX_FLAGS_OPTIMIZE_FOR_DEBUG}")
    endif()
endfunction()
