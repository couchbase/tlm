EXECUTE_PROCESS(COMMAND dialyzer --plt ${PLT_FILE} --check_plt
  RESULT_VARIABLE result)
IF(NOT "${result}" STREQUAL "0")
  MESSAGE(STATUS "dialyzer --check_plt failed. Deleting ${PLT_FILE}")
  FILE(REMOVE ${PLT_FILE})
ENDIF(NOT "${result}" STREQUAL "0")
