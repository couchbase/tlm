# Support for running code coverage reporting.
#
# Usage:
# 1). Add a call to ADD_COVERAGE_REPORT() to the module(s) you wish to
#     obtain code coverage reports on.
# 2). Enable the option CB_CODE_COVERAGE (e.g. pass -DCB_CODE_COVERAGE=ON to cmake).
# 3). Build as normal.
# 4). Run unit test(s) to exercise the codebase.
# 5). Run `make coverage-report-html` and/or `coverage-report-xml`
#     (from the selected module subdirectory) to generate the reports.
# 6) (Optional) to zero coverage counters before a re-run run `make coverage-zero-counters`.


OPTION(CB_CODE_COVERAGE "Enable code coverage testing."
       OFF)

IF (CB_CODE_COVERAGE)
    FIND_PROGRAM(GCOV_PATH gcov)
    FIND_PROGRAM(GCOVR_PATH gcovr)

    IF (NOT GCOV_PATH)
        MESSAGE(STATUS "gcov not found.")
    ENDIF (NOT GCOV_PATH)

    IF (NOT GCOVR_PATH)
        MESSAGE(STATUS "gcovr [www.gcovr.com] not found.")
    ENDIF ()

    IF (NOT GCOV_PATH OR NOT GCOVR_PATH)
       MESSAGE(FATAL_ERROR "CB_CODE_COVERAGE enabled but one of more required tools not found - cannot continue.")
    ENDIF()
ENDIF(CB_CODE_COVERAGE)

# Defines a coverage report for the current module. If CB_CODE_COVERAGE is enabled,
# collate all code coverage results belonging to the current module and generate
# coverage reports.
FUNCTION(ENABLE_CODE_COVERAGE_REPORT)
   IF (CB_CODE_COVERAGE)
      MESSAGE(STATUS "Setting up code coverage for ${PROJECT_NAME}")

      ADD_CUSTOM_TARGET(coverage-zero-counters
                        COMMAND find . -name *.gcda -exec rm {} \;
                        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                        COMMENT "Zeroing coverage counters for objects in ${CMAKE_CURRENT_BINARY_DIR}"
                        VERBATIM)

      ADD_CUSTOM_TARGET(coverage-report-html
                        COMMAND ${CMAKE_COMMAND} -E remove_directory coverage
                        COMMAND ${CMAKE_COMMAND} -E make_directory coverage
                        COMMAND ${GCOVR_PATH} --root=${CMAKE_SOURCE_DIR} --filter="${CMAKE_CURRENT_SOURCE_DIR}/.*" --html --html-details -o coverage/index.html
                        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                        COMMENT "Generating code coverage report for ${PROJECT_NAME} to ${CMAKE_CURRENT_BINARY_DIR}/coverage/index.html")

      ADD_CUSTOM_TARGET(coverage-report-xml
                        COMMAND ${GCOVR_PATH} --root=${CMAKE_SOURCE_DIR} --filter="${CMAKE_CURRENT_SOURCE_DIR}/.*" --xml -o coverage.xml
                        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                        COMMENT "Generating code coverage report for ${PROJECT_NAME} to ${CMAKE_CURRENT_BINARY_DIR}/coverage.xml")
   ENDIF (CB_CODE_COVERAGE)
ENDFUNCTION()
