#[===[
The fuzztest package supports Linux/macOS only.

The variables FUZZTEST_FUZZING_MODE and FUZZTEST_COMPATIBILITY_MODE are used to
configure the fuzztest package.

The following configurations are supported:
 - FUZZTEST_FUZZING_MODE=OFF uses a cbdep for fuzztest (default)
 - FUZZTEST_FUZZING_MODE=ON builds fuzztest from source and uses the native
   fuzzing engine.
 - FUZZTEST_COMPATIBILITY_MODE=libfuzzer builds fuzztest from source and uses
   libfuzzer as the fuzzing engine.

When the above variables are not specified (or set to OFF), the library is build
in unit test mode (no fuzzing). When using a fuzzing configuration, the fuzztest
package will be built from source. For convenience, CB_LIBFUZZER implies fuzzing
and sets FUZZTEST_COMPATIBILITY_MODE=libfuzzer.

The variable HAVE_FUZZTEST is set to ON if the fuzztest library is available.
]===]

include(ExternalProject)

# If CB_LIBFUZZER is specified and FUZZTEST_FUZZING_MODE is not specified,
# then we need to set FUZZTEST_FUZZING_MODE to libfuzzer.
if(CB_LIBFUZZER AND NOT FUZZTEST_FUZZING_MODE)
    # Disable the google/fuzztest native fuzzing engine (centipede) in favor of
    # libfuzzer.
    set(FUZZTEST_COMPATIBILITY_MODE libfuzzer CACHE STRING "Set by CB_LIBFUZZER" FORCE)
endif()

if (NOT FUZZTEST_FUZZING_MODE AND NOT DEFINED FUZZTEST_COMPATIBILITY_MODE)
    # Need to have GTest before we can use the fuzztest package.
    # Make sure we've ordered the dependencies correctly if this fails.
    if(NOT GTest_FOUND)
        message(FATAL_ERROR "GTest not found. Ensure it is available before building including this module.")
    endif()

    # We also need absl from the fuzztest package if it has not been found yet
    if(NOT DEFINED absl_ROOT AND EXISTS ${fuzztest_ROOT}/lib/cmake/absl)
        set(absl_ROOT ${fuzztest_ROOT}/lib/cmake/absl)
    endif()
    find_package(absl CONFIG)

    # Use the re2 package from the fuzztest package if it has not been found yet
    if(NOT DEFINED re2_ROOT AND EXISTS ${fuzztest_ROOT}/lib/cmake/re2)
        set(re2_ROOT ${fuzztest_ROOT}/lib/cmake/re2)
    endif()
    find_package(re2 CONFIG)

    if(NOT DEFINED fuzztest_ROOT AND EXISTS ${CMAKE_BINARY_DIR}/tlm/deps/fuzztest.exploded)
        set(fuzztest_ROOT ${CMAKE_BINARY_DIR}/tlm/deps/fuzztest.exploded)
    endif()

    find_package(fuzztest CONFIG)
    if(fuzztest_FOUND)
        set(HAVE_FUZZTEST ON)
    endif()
endif()

# Windows is not a supported platform for fuzztest.
if (NOT fuzztest_FOUND AND UNIX)
    # We need to build it from source, if the fuzztest cbdep cannot be used
    # because of the specified configuration.
    include(PopulateFuzzTestDependencies)
    message(STATUS "The fuzztest package will be built from source (FUZZTEST_FUZZING_MODE=${FUZZTEST_FUZZING_MODE};FUZZTEST_COMPATIBILITY_MODE=${FUZZTEST_COMPATIBILITY_MODE})")

    # Get the directory COMPILE_OPTIONS before modifying it.
    get_directory_property(original_compile_options COMPILE_OPTIONS)
    # Disable warnings common when building fuzztest and it's dependencies from
    # source. Other build configurations will still have these warnings.
    add_compile_options(
        -Wno-dtor-name
        -Wno-gcc-compat
        -Wno-gnu-anonymous-struct
        -Wno-missing-field-initializers
        -Wno-nested-anon-types
        -Wno-sign-compare
        -Wno-c99-extensions
        -Wno-deprecated-declarations
        -Wno-shorten-64-to-32
    )

    FetchContent_Declare(
        fuzztest
        GIT_REPOSITORY https://github.com/couchbasedeps/fuzztest.git
        GIT_TAG ${CBDEP_fuzztest_VERSION}
    )
    FetchContent_MakeAvailable(fuzztest)

    # Add the original compile options back.
    get_directory_property(new_compile_options COMPILE_OPTIONS)
    set_property(DIRECTORY ${fuzztest_SOURCE_DIR} PROPERTY COMPILE_OPTIONS ${original_compile_options})
    set_property(DIRECTORY PROPERTY COMPILE_OPTIONS ${original_compile_options})

    # Anything that links against fuzztest should also disable the warnings.
    target_compile_options(fuzztest_fuzztest INTERFACE ${new_compile_options})

    # Allow to user to check for fuzztest.
    set(HAVE_FUZZTEST ON)
endif()
