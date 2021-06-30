include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)
include(CMakePushCheckState)

option(CB_LIBFUZZER "Enable LibFuzzer (https://llvm.org/docs/LibFuzzer.html)")

if (CB_LIBFUZZER)
    cmake_push_check_state(RESET)
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=fuzzer-no-link")
    check_c_compiler_flag("-fsanitize=fuzzer-no-link" HAVE_FLAG_SANITIZE_FUZZER_C)
    check_cxx_compiler_flag("-fsanitize=fuzzer-no-link" HAVE_FLAG_SANITIZE_FUZZER_CXX)
    cmake_pop_check_state()

    if (HAVE_FLAG_SANITIZE_FUZZER_C AND HAVE_FLAG_SANITIZE_FUZZER_CXX)
        set(LIBFUZZER_SANITIZER_FLAG "-fsanitize=fuzzer-no-link")
        set(LIBFUZZER_SANITIZER_FLAG_DISABLE "-fno-sanitize=fuzzer-no-link")
        add_definitions(-DFUZZ_SANITIZER)
        message(STATUS "LibFuzzer Sanitizer enabled")
    else ()
        message(FATAL_ERROR "CB_LIBFUZZER enabled but compiler doesn't support fuzzer-no-link - cannot continue.")
    endif ()
endif ()

function(add_sanitize_libfuzzer TARGET)
    if (CB_LIBFUZZER)
        set_property(TARGET ${TARGET} APPEND_STRING
                     PROPERTY COMPILE_FLAGS " ${LIBFUZZER_SANITIZER_FLAG}")
        set_property(TARGET ${TARGET} APPEND_STRING
                     PROPERTY LINK_FLAGS " ${LIBFUZZER_SANITIZER_FLAG}")
    endif ()
endfunction()

# Link a program and supply the main driver for libfuzzer
function(cb_link_libfuzzer_main TARGET)
    target_link_options(${TARGET} PUBLIC -fsanitize=fuzzer)
endfunction()

function(remove_sanitize_libfuzzer TARGET)
    if (CB_LIBFUZZER)
        remove_from_property(${TARGET} COMPILE_OPTIONS ${LIBFUZZER_SANITIZER_FLAG})
        remove_from_property(${TARGET} LINK_OPTIONS ${LIBFUZZER_SANITIZER_FLAG})
        set_property(TARGET ${TARGET} APPEND_STRING
                     PROPERTY COMPILE_FLAGS " ${LIBFUZZER_SANITIZER_FLAG_DISABLE}")
        set_property(TARGET ${TARGET} APPEND_STRING
                     PROPERTY LINK_FLAGS " ${LIBFUZZER_SANITIZER_FLAG_DISABLE}")
    endif ()
endfunction()
