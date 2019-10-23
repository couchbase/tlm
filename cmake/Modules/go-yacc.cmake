# Set GOROOT environment
SET (ENV{GOROOT} "${GOROOT}")

# Execute "go yacc"
IF (DEFINED ENV{VERBOSE})
  MESSAGE (STATUS "Executing: ${GOYACC_EXECUTABLE} ${YFILE}")
endif()
EXECUTE_PROCESS (RESULT_VARIABLE _failure
  COMMAND "${GOYACC_EXECUTABLE}" "${YFILE}")
IF (_failure)
  MESSAGE (FATAL_ERROR "Failed running go yacc")
ENDIF (_failure)

