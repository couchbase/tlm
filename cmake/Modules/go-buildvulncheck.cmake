IF (DEFINED ENV{VERBOSE})
  SET (CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)
endif()

# Set GOROOT environment
SET (ENV{GOROOT} "${GOROOT}")
SET (GO_EXECUTABLE "${GOROOT}/bin/go")

# Prevent Go from automatically downloading a different toolchain version
# based on 'toolchain' directives in go.mod files.
SET (ENV{GOTOOLCHAIN} "local")

# Use GOPATH and GOCACHE in the build tree, the same as other Go targets.
SET (ENV{GOPATH} "${GO_BINARY_DIR}")
SET (ENV{GOCACHE} "${GO_BINARY_DIR}/cache")

# Set GOBIN to direct the output somewhere else
GET_FILENAME_COMPONENT (_outdir "${GOVULNCHECK_EXE}" PATH)
SET (ENV{GOBIN} "${_outdir}")

EXECUTE_PROCESS (RESULT_VARIABLE _failure
  COMMAND "${GO_EXECUTABLE}" install -modcacherw
    golang.org/x/vuln/cmd/govulncheck@${GOVULNCHECK_VERSION})

IF (_failure)
  MESSAGE (FATAL_ERROR "Failed running go install for govulncheck")
ENDIF (_failure)
