# Unset GOROOT in the environment (which will make Go figure it out from
# the path to the go compiler on disk, which is what we want)
SET (ENV{GOROOT})

# Use GOPATH to tell Go where to store downloaded and cached Go modules.
# It will put things into pkg/mod.
SET (ENV{GOPATH} "${GO_BINARY_DIR}")

# Use GOCACHE to tell Go where to store intermediate compilation artifacts.
# It places things directly into this directory, so we append /cache.
SET (ENV{GOCACHE} "${GO_BINARY_DIR}/cache")

# Execute "go mod tidy".
SET (CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)
EXECUTE_PROCESS (
  RESULT_VARIABLE _failure
  COMMAND "${GOEXE}" mod tidy -v)
IF (NOT WIN32)
  # Golang very annoyingly leaves all downloaded module directories as
  # read-only, so not even rm -rf works. Go 1.14 introduces a new flag
  # GOFLAGS=-modcacherw which fixes this, but until we have switched
  # entirely to 1.14 or higher, here's a work-around:
  EXECUTE_PROCESS (
    COMMAND find "${GO_BINARY_DIR}/pkg/mod" -type d -print0
    COMMAND xargs -0 chmod u+w
  )
ENDIF ()

IF (_failure)
  MESSAGE (FATAL_ERROR "Failed running go mod tidy")
ENDIF (_failure)
