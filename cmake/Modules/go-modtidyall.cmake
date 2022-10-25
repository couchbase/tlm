# Write a checksum of the current repo state into the variable named by "var"
MACRO (_DETERMINE_REPO_CHECKSUM var)
  EXECUTE_PROCESS (
    COMMAND repo diff -u
    OUTPUT_VARIABLE _diff_output
    RESULT_VARIABLE _failed
    ERROR_VARIABLE _stderr
  )
  IF (_failed)
    MESSAGE (FATAL_ERROR "Error running 'repo diff': ${_stderr}")
  ENDIF ()

  STRING (SHA256 ${var} "${_diff_output}")
ENDMACRO (_DETERMINE_REPO_CHECKSUM)

# Get initial state of repo sync
_DETERMINE_REPO_CHECKSUM (_init_checksum)

# Loop forever (will break out manually)
WHILE (1)
  # Execute 'go mod tidy' for all projects
  EXECUTE_PROCESS (
    COMMAND "${CMAKE_COMMAND}" --build . --target go-mod-tidy
    RESULT_VARIABLE _failed
    ERROR_VARIABLE _stderr
  )
  IF (_failed)
    MESSAGE (FATAL_ERROR "Error running 'go-mod-tidy' target: ${_stderr}")
  ENDIF ()

  # Get new repo checksum
  _DETERMINE_REPO_CHECKSUM (_curr_checksum)

  # If no changes, great! All done
  IF (_curr_checksum STREQUAL _init_checksum)
    BREAK ()
  ENDIF ()

  MESSAGE (STATUS "Repo was changed - re-running go-mod-tidy")
  SET (_init_checksum "${_curr_checksum}")
ENDWHILE ()
