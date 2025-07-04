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

OPTION(CB_CODE_COVERAGE "Enable code coverage testing."
       OFF)

IF (CB_CODE_COVERAGE)
    FIND_PROGRAM(GCOV_PATH gcov)
    FIND_PROGRAM(GCOVR_PATH gcovr)

    IF (GCOV_PATH)
        EXECUTE_PROCESS(COMMAND ${GCOV_PATH} --version
                        OUTPUT_VARIABLE GCOV_VERSION
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
        MESSAGE(STATUS "gcov found: ${GCOV_PATH} version: ${GCOV_VERSION}")
    ELSE (GCOV_PATH)
        MESSAGE(STATUS "gcov not found.")
    ENDIF (GCOV_PATH)

    IF (GCOVR_PATH)
        EXECUTE_PROCESS(COMMAND ${GCOVR_PATH} --version
                        OUTPUT_VARIABLE GCOVR_VERSION
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
        MESSAGE(STATUS "gcovr found: ${GCOVR_PATH} version: ${GCOVR_VERSION}")
    ELSE (GCOVR_PATH)
        MESSAGE(STATUS "gcovr [www.gcovr.com] not found. HTML / XML coverage report rules will not be available")
    ENDIF (GCOVR_PATH)

    IF (NOT GCOV_PATH)
       MESSAGE(FATAL_ERROR "CB_CODE_COVERAGE enabled but a required tool (gcov) was not found - cannot continue.")
    ENDIF()
ENDIF(CB_CODE_COVERAGE)

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
FUNCTION(ENABLE_CODE_COVERAGE_REPORT)
   GET_FILENAME_COMPONENT(_cc_project ${CMAKE_CURRENT_BINARY_DIR} NAME)

   IF (CB_CODE_COVERAGE)
      MESSAGE(STATUS "Setting up code coverage for ${PROJECT_NAME}")

      ADD_CUSTOM_TARGET(${_cc_project}-coverage-zero-counters
                        COMMAND find . -name *.gcda -exec rm {} \;
                        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                        COMMENT "Zeroing coverage counters for objects in ${CMAKE_CURRENT_BINARY_DIR}"
                        VERBATIM)

      IF (GCOVR_PATH)
          ADD_CUSTOM_TARGET(${_cc_project}-coverage-report-html
                            COMMAND ${CMAKE_COMMAND} -E remove_directory coverage
                            COMMAND ${CMAKE_COMMAND} -E make_directory coverage
                            COMMAND ${GCOVR_PATH} --root=${CMAKE_SOURCE_DIR} --filter="${CMAKE_CURRENT_SOURCE_DIR}/.*" --html --html-details -o coverage/index.html
                            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                            COMMENT "Generating code coverage report for ${PROJECT_NAME} to ${CMAKE_CURRENT_BINARY_DIR}/coverage/index.html")

          ADD_CUSTOM_TARGET(${_cc_project}-coverage-report-xml
                            COMMAND ${GCOVR_PATH} --root=${CMAKE_SOURCE_DIR} --filter="${CMAKE_CURRENT_SOURCE_DIR}/.*" --xml -o coverage.xml
                            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                            COMMENT "Generating code coverage report for ${PROJECT_NAME} to ${CMAKE_CURRENT_BINARY_DIR}/coverage.xml")
      ENDIF (GCOVR_PATH)
   ENDIF (CB_CODE_COVERAGE)
ENDFUNCTION()
