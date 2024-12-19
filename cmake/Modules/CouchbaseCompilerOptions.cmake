include(CheckIncludeFileCXX)

# Set C++ standard to 20 on Windows, 17 on other platforms while we're
# solving the problems with C++20 on clang-15.0.7 used by our commit
# validation jobs. We need C++20 on windows in order to build the
# system due to some problems with Folly and our version of the
# MSVC compiler. We could have enabled C++20 on all platforms
# except for clang on linux (not used in production, but that
# would make things fail to compile just on the CV jobs if people
# started to use C++20 features in the code).
if (WIN32)
    set(CMAKE_CXX_STANDARD 20)
else()
    set(CMAKE_CXX_STANDARD 17)
endif ()

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

message(STATUS "C++ compiler version: ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "C++ language version: ${CMAKE_CXX_STANDARD}")

option(COUCHBASE_OMIT_FRAME_POINTER
       "Allow omission of frame pointer"
       True)

if (UNIX AND NOT APPLE)
    # Add --build-id=sha1 to the linker if the linker supports it to get
    # rid of "WARNING: No build ID note found in <...>" when building
    # an RPM package
  include(CheckCCompilerFlag)
  check_c_compiler_flag(-Wl,--build-id=sha1 HAVE_LINKER_BUILD_ID)
  if (HAVE_LINKER_BUILD_ID)
    string(APPEND CMAKE_EXE_LINKER_FLAGS " -Wl,--build-id=sha1")
    string(APPEND CMAKE_SHARED_LINKER_FLAGS " -Wl,--build-id=sha1")
  endif ()
endif()

# If building with a version of compiler which defaults to PIE code
# (--enable-default-pie) such as GCC 10.2+ or Clang 15+, we can
# encounter linker errors when linking against precompiled static
# libraries similar to:
#
#     /usr/bin/ld: foo.a(bar.cc.o): relocation R_X86_64_32 against `.rodata.str1.8' can not be used when making a PIE object; recompile with -fPIC
#
# Address this by disabling the effect of '--enable-default-pie' - set
# the default to non- position-independent executables.
#
include(CheckCCompilerFlag)
check_c_compiler_flag(-no-pie HAVE_NO_PIE)
if (HAVE_NO_PIE)
  string(APPEND CMAKE_EXE_LINKER_FLAGS " -no-pie")
endif ()

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
    # Verify that compiler actually supports the main C++17 features used -
    # some compilers *couch* AppleClang 9 *couch* claim support C++17 but
    # are missing core library features.
    check_include_file_cxx(optional HAVE_OPTIONAL)
    if (NOT HAVE_OPTIONAL)
        unset(HAVE_OPTIONAL)
        message(FATAL_ERROR "C++ compiler claims C++17 support but is missing required header <optional>. Check if your compiler (${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}) fully supports C++17.")
    endif ()
    check_include_file_cxx(variant HAVE_VARIANT)
    if (NOT HAVE_VARIANT)
        unset(HAVE_VARIANT)
        message(FATAL_ERROR "C++ compiler claims C++17 support but is missing required header <variant>. Check if your compiler (${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}) fully supports C++17.")
    endif ()
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

# Check function attribute availability
include(CheckCCompilerFlag)

# Printf-style format checking
check_c_source_compiles("int main() {
      return 0;
}
int my_printf(const char* fmt, ...) __attribute__((format (printf, 1, 2)));" HAVE_ATTR_FORMAT)

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
# to balance compile time and execution time of the unit tests:
# Much of the unit test code is expensive to compile with production-level
# optimization, either simply due to its size, or things like GMock / GTest
# template instantiation, so it's undesirable to compile with Release-level
# optimization, however without _any_ optimizations the unit test code can
# take a long time to execute.
set(CMAKE_CXX_FLAGS_DEBUGOPTIMIZED "${CB_FLAGS_OPTIMIZE_FOR_DEBUG}"
        CACHE
        STRING "Flags used by the C++ compiler during DebugOptimized builds."
        FORCE )
set(CMAKE_C_FLAGS_DEBUGOPTIMIZED "${CB_FLAGS_OPTIMIZE_FOR_DEBUG}"
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
