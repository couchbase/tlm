IF (DEFINED ENV{VERBOSE})
  SET (CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)
endif()

# Set GOROOT environment
SET (ENV{GOROOT} "${GOROOT}")
SET (GO_EXECUTABLE "${GOROOT}/bin/go")

# Prevent Go from automatically downloading a different toolchain version
# based on 'toolchain' directives in go.mod files.
SET (ENV{GOTOOLCHAIN} "local")

# Set GOBIN to direct the output somewhere else
GET_FILENAME_COMPONENT (_outdir "${GOYACC_EXE}" PATH)
SET (ENV{GOBIN} "${_outdir}")

# Execute "go install".
EXECUTE_PROCESS (RESULT_VARIABLE _failure
  COMMAND "${GO_EXECUTABLE}" install golang.org/x/tools/cmd/goyacc@v0.24.0)
IF (_failure)
  MESSAGE (FATAL_ERROR "Failed running go install for goyacc")
ENDIF (_failure)
