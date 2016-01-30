# Set GOROOT environment
SET (ENV{GOROOT} "${GOROOT}")
SET (GO_EXECUTABLE "${GOROOT}/bin/go")

# Execute "go yacc"
MESSAGE (STATUS "Executing: ${_goroot}/bin/go tool yacc ${YFILE}")
EXECUTE_PROCESS (RESULT_VARIABLE _failure
  COMMAND "${GO_EXECUTABLE}" tool yacc "${YFILE}")
IF (_failure)
  MESSAGE (FATAL_ERROR "Failed running go yacc")
ENDIF (_failure)

