# This module needs to be included when using fuzztest.
# It defines functions to link against the fuzztest library.
# When it is included, it will also add the fuzzing flags to the project.

function(cb_link_fuzztest name)
    target_link_libraries(
        ${name}
        PUBLIC
        fuzztest::fuzztest
        fuzztest::init_fuzztest
    )
endfunction()

function(cb_link_fuzztest_main name)
    target_link_libraries(
        ${name}
        PUBLIC
        fuzztest::fuzztest_gtest_main
    )
endfunction()

fuzztest_setup_fuzzing_flags()
add_definitions(-DHAVE_FUZZTEST)
