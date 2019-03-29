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

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

message(STATUS "C++ compiler version: ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "C++ language version: ${CMAKE_CXX_STANDARD}")

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
