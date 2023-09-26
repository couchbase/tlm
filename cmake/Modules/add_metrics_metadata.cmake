# Different steps based on whether 'jq' was found
IF (JQ_EXE)
  EXECUTE_PROCESS(
    COMMAND "${JQ_EXE}" . --sort-keys "${JSON_IN}"
    OUTPUT_FILE "${JSON_OUT}"
    RESULT_VARIABLE _failure
    ERROR_VARIABLE _errormsg
  )
  IF (_failure)
    MESSAGE (FATAL_ERROR "Error generating ${JSON_OUT}: ${_errormsg}")
  ENDIF ()
ELSE (JQ_EXE)
  # Use CMake to verify the JSON contents. CMake is unfortunately forgiving
  # of some JSON errors, but this is better than nothing.
  FILE (READ "${JSON_IN}" _mmjson)
  STRING (JSON _unused ERROR_VARIABLE _error MEMBER "${_mmjson}" 1)
  IF (_error)
    MESSAGE (FATAL_ERROR "Error parsing ${JSON_IN}: ${_error}")
  ENDIF (_error)

  # Write the original contents to the output file
  FILE (WRITE "${JSON_OUT}" "${_mmjson}")
ENDIF (JQ_EXE)
