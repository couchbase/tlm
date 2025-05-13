include(FetchContent)

# Find GTest
find_package(GTest REQUIRED CONFIG)

# Declare GTest as a FetchContent target under the name googletest which is
# what fuzztest expects. By declaring NAMES GTest, we force the FetchContent
# to find the library under the name we use.
FetchContent_Declare(
    googletest
    SOURCE_DIR ${GTest_ROOT}
    FIND_PACKAGE_ARGS NAMES GTest)
FetchContent_MakeAvailable(googletest)

# Disable the C++ tests for antlr.
set(ANTLR_BUILD_CPP_TESTS OFF)
