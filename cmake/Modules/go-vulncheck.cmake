IF (DEFINED ENV{VERBOSE})
    MESSAGE (STATUS "Executing: ${GOVULNCHECK_EXE} on ${BINARY}")
endif()

SET (ENV{GOROOT} "${GOROOT}")
SET (ENV{GOTOOLCHAIN} "local")

GET_FILENAME_COMPONENT (_outdir "${OUTPUT}" PATH)
FILE (MAKE_DIRECTORY "${_outdir}")

EXECUTE_PROCESS (RESULT_VARIABLE _failure
  COMMAND "${GOVULNCHECK_EXE}" -mode binary -format json "${BINARY}"
  OUTPUT_FILE "${OUTPUT}"
  ERROR_VARIABLE _stderr)

IF (_failure)
  MESSAGE (FATAL_ERROR "Failed running govulncheck on ${BINARY}: ${_stderr}")
ENDIF (_failure)
