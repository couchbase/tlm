# Support for running code coverage reporting.
#
# Usage:
# 1). Add a call to ENABLE_CODE_COVERAGE_REPORT() to the module(s) you wish to
#     obtain code coverage reports on.
# 2). Enable the option CB_CODE_COVERAGE (e.g. pass -DCB_CODE_COVERAGE=ON to cmake).
# 3). Build as normal.
# 4). Run unit test(s) to exercise the codebase.
# 5). Run `make coverage-report-html` and/or `coverage-report-xml`
#     (from the selected module subdirectory) to generate the reports.
# 6) (Optional) to zero coverage counters before a re-run run `make coverage-zero-counters`.
#
# Note 1: Do make sure you have gcov and gcovr installed!
#
# Note 2: If you followed all the steps above but the coverage report is empty,
# try to use "touch CMakeCache.txt" in your build directory, then rebuild the project and rerun the coverage report

option(CB_CODE_COVERAGE "Enable code coverage testing."
       OFF)

if (CB_CODE_COVERAGE)
    # GCC uses gcov, Clang uses llvm-cov.
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        find_program(GCOV_PATH gcov)

        if (GCOV_PATH)
            execute_process(COMMAND ${GCOV_PATH} --version
                            OUTPUT_VARIABLE GCOV_VERSION
                            OUTPUT_STRIP_TRAILING_WHITESPACE)
            message(STATUS "gcov found: ${GCOV_PATH} version: ${GCOV_VERSION}")
        else()
            message(FATAL_ERROR "CB_CODE_COVERAGE enabled but a required tool (gcov) was not found - cannot continue.")
        endif()

        set(GCOV_EXECUTABLE ${GCOV_PATH})
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        find_program(LLVM_COV_PATH llvm-cov)

        if (LLVM_COV_PATH)
            execute_process(COMMAND ${LLVM_COV_PATH} --version
                            OUTPUT_VARIABLE LLVM_COV_VERSION
                            OUTPUT_STRIP_TRAILING_WHITESPACE)
            message(STATUS "llvm-cov found: ${LLVM_COV_PATH} version: ${LLVM_COV_VERSION}")
        else()
            message(FATAL_ERROR "CB_CODE_COVERAGE enabled but a required tool (llvm-cov) was not found - cannot continue.")
        endif()

        set(GCOV_EXECUTABLE "${LLVM_COV_PATH}" gcov)
    else()
        message(FATAL_ERROR "CB_CODE_COVERAGE enabled but ${CMAKE_CXX_COMPILER_ID} is not supported.")
    endif()

    find_program(GCOVR_PATH gcovr)
    if (GCOVR_PATH)
        execute_process(COMMAND ${GCOVR_PATH} --version
                        OUTPUT_VARIABLE GCOVR_VERSION
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
        message(STATUS "gcovr found: ${GCOVR_PATH} version: ${GCOVR_VERSION}")
    else()
        message(STATUS "gcovr [www.gcovr.com] not found. HTML / XML coverage report rules will not be available")
    endif()
endif()

# Defines a coverage report for the current module. If CB_CODE_COVERAGE is enabled,
# adds three new targets to that module:
#   <project>-coverage-zero-counters: Zeros the code coverage counters for the module.
#   <project>-coverage-report-html:   Generates a code coverage report in HTML.
#   <project>-coverage-report-xml:    Generates a code coverage report in XML.
#
# Note: The html and xml report targets are not added if gcovr is not found
#
# Usage:
# 1) `make <project>-coverage-zero-counters` to clear any counters from
#    previously-executed programs.
# 2) Run whatever programs to excercise the code (unit tests, etc).
# 3) `make <project>-coverage-report-{html,xml}` to generate a report.
#
function(ENABLE_CODE_COVERAGE_REPORT)
   get_filename_component(_cc_project ${CMAKE_CURRENT_BINARY_DIR} NAME)

   if (CB_CODE_COVERAGE)
      message(STATUS "Setting up code coverage for ${PROJECT_NAME}")

      add_custom_target(${_cc_project}-coverage-zero-counters
                        COMMAND find . -name *.gcda -exec rm {} \;
                        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                        COMMENT "Zeroing coverage counters for objects in ${CMAKE_CURRENT_BINARY_DIR}"
                        VERBATIM)

      if (GCOVR_PATH)
          set(GCOVR_ARGS
            --gcov-executable ${GCOV_EXECUTABLE}
            --root=${CMAKE_SOURCE_DIR}
            "--filter=${CMAKE_CURRENT_SOURCE_DIR}/.*"
            # Allow same function on different lines. Instead of merging keep
            # the functions separate. The default "abort" fails for our fork
            # of folly/AtomicBitSet.h, which exists in folly and in kv_engine.
            --merge-mode-functions=separate
          )
          add_custom_target(${_cc_project}-coverage-report-html
                            COMMAND ${CMAKE_COMMAND} -E remove_directory coverage
                            COMMAND ${CMAKE_COMMAND} -E make_directory coverage
                            COMMAND ${GCOVR_PATH} ${GCOVR_ARGS} --html --html-details -o coverage/index.html
                            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                            COMMENT "Generating code coverage report for ${PROJECT_NAME} to ${CMAKE_CURRENT_BINARY_DIR}/coverage/index.html")

          add_custom_target(${_cc_project}-coverage-report-xml
                            COMMAND ${GCOVR_PATH} ${GCOVR_ARGS} --xml -o coverage.xml
                            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                            COMMENT "Generating code coverage report for ${PROJECT_NAME} to ${CMAKE_CURRENT_BINARY_DIR}/coverage.xml")
      endif()
   endif()
endfunction()
