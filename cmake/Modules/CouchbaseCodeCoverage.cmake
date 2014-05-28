FIND_PROGRAM(GCOV_PATH gcov)
FIND_PROGRAM(LCOV_PATH lcov)
FIND_PROGRAM(GENHTML_PATH genhtml)

SET(CB_CODE_COVERAGE TRUE)

IF (NOT GCOV_PATH)
    MESSAGE(STATUS "gcov not found, code coverage disabled")
    SET(CB_CODE_COVERAGE FALSE)
ENDIF (NOT GCOV_PATH)

IF (NOT LCOV_PATH)
    MESSAGE(STATUS "lcov not found, code coverage disabled")
    SET(CB_CODE_COVERAGE FALSE)
ENDIF (NOT LCOV_PATH)

IF (NOT GENHTML_PATH)
    MESSAGE(STATUS "genhtml not found, code coverage disabled")
    SET(CB_CODE_COVERAGE FALSE)
ENDIF (NOT GENHTML_PATH)

FUNCTION(SETUP_COVERAGE_TARGET _target _test _output)
   IF (${CB_CODE_COVERAGE})
       MESSAGE(STATUS "Setting up ${_target}")
       SET_TARGET_PROPERTIES(${_test} PROPERTIES COMPILE_FLAGS "-g -O0 -fprofile-arcs -ftest-coverage")
       SET_TARGET_PROPERTIES(${_test} PROPERTIES LINK_FLAGS "-fprofile-arcs -ftest-coverage")

       ADD_CUSTOM_TARGET(${_target}
                      COMMAND ${LCOV_PATH} --directory ${_test} --zerocounters
                      COMMAND ${_test}
                      COMMAND ${LCOV_PATH} --directory CMakeFiles/${_test}.dir --capture --output-file ${_output}.info
                      COMMAND ${LCOV_PATH} --remove ${_output}.info 'tests/*' '/usr/*' --output-file ${_output}.info.cleaned
                      COMMAND ${GENHTML_PATH} -o ${_output} ${_output}.info.cleaned
                      COMMAND ${CMAKE_COMMAND} -E remove ${_output}.info ${_output}.info.cleaned
                      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                      COMMENT "Resetting code coverage counters to zero.\nProcessing code coverage counters and generating report.")
       # Show info where to find the report
       ADD_CUSTOM_COMMAND(TARGET ${_target} POST_BUILD
                          COMMAND ;
                          COMMENT "Open ./${_output}/index.html in your browser to view the coverage report.")
   ELSE (${CB_CODE_COVERAGE})
      MESSAGE(STATUS "Missing tools for code coverage. Ignoring ${_target}")
   ENDIF (${CB_CODE_COVERAGE})
ENDFUNCTION()
