MACRO (EXPORT_FLAGS var envvar flag)
  IF (${var})
    SET (_value)
    FOREACH (_dir ${${var}})
      SET (_value "${_value} ${flag}${_dir}")
    ENDFOREACH (_dir)
    SET (ENV{${envvar}} "$ENV{${envvar}} ${_value}")
  ENDIF (${var})
ENDMACRO (EXPORT_FLAGS)

# Convert CGO_xxx_DIRS values into platform- and compiler-appropriate
# CGO_ environment variables. Currently only known to work on Linux
# and probably Mac environments.
EXPORT_FLAGS (CGO_INCLUDE_DIRS CGO_CPPFLAGS "-I")
EXPORT_FLAGS (CGO_LIBRARY_DIRS CGO_LDFLAGS "-L")
IF (NOT APPLE)
  EXPORT_FLAGS (CGO_LIBRARY_DIRS CGO_LDFLAGS "-Wl,-rpath-link=")
ENDIF ()

IF (CGO_CFLAGS)
  SET (ENV{CGO_CFLAGS} "$ENV{CGO_CFLAGS} ${CGO_CFLAGS}")
ENDIF ()

IF (CGO_LDFLAGS)
  SET (ENV{CGO_LDFLAGS} "$ENV{CGO_LDFLAGS} ${CGO_LDFLAGS}")
ENDIF ()

IF (NOT WIN32)
  IF (DEFINED CB_THREADSANITIZER)
    # Only use the CMAKE C compiler for cgo on non-Windows platforms;
    # on Windows we use a different compiler (gcc) for cgo than for
    # the main build MSVC).
    SET (ENV{CC} "${CMAKE_C_COMPILER}")
  ENDIF (DEFINED CB_THREADSANITIZER)
ENDIF()

# QQQ TOTAL HACK to enable CGO binaries to find Couchbase-built shared
# libraries.  This will clearly only work on Linux ELF-based systems,
# and only for those libraries which are installed in the correct path
# relative to the installed location of the Go-built executable. I'm still
# trying to figure out how to handle this correctly.
SET (ENV{LD_RUN_PATH} "$ORIGIN/../lib")

# Always use -x if CB_GO_DEBUG is set
IF ($ENV{CB_GO_DEBUG})
  SET (_go_debug -x)
ENDIF ($ENV{CB_GO_DEBUG})

# check if race detector flag is set
IF (CB_GO_RACE_DETECTOR)
  SET (_go_race -race)
ENDIF (CB_GO_RACE_DETECTOR)

# Unset GOROOT in the environment (which will make Go figure it out from
# the path to the go compiler on disk, which is what we want)
SET (ENV{GOROOT})

# Use GOPATH to tell Go where to store downloaded and cached Go modules.
# It will put things into pkg/mod.
SET (ENV{GOPATH} "${GO_BINARY_DIR}")

# Set GO111MODULE since we're by definition building with modules (just in
# case it's set to a bad value in the environment)
SET (ENV{GO111MODULE} "on")

# Use GOCACHE to tell Go where to store intermediate compilation artifacts.
# It places things directly into this directory, so we append /cache.
SET (ENV{GOCACHE} "${GO_BINARY_DIR}/cache")

# If this is a production build, set/override GOPROXY.
IF (CB_PRODUCTION_BUILD)
  SET (ENV{GOPROXY} "http://goproxy.build.couchbase.com/")
ENDIF ()

# Attempt to hide build-system-specific paths in resulting binaries.
get_filename_component(REPOSYNC "${REPOSYNC}" REALPATH)
SET (GCFLAGS "-trimpath=${REPOSYNC}" ${GCFLAGS})
SET (ASMFLAGS "-trimpath=${REPOSYNC}")

# Work around Windows Go 1.15 link error - MB-44988
IF (WIN32)
  SET (_go_buildmode "-buildmode=exe")
ENDIF ()

# Execute "go build".
SET (CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)
EXECUTE_PROCESS (
  RESULT_VARIABLE _failure
  COMMAND "${GOEXE}" build
    "-tags=${GOTAGS}" "-gcflags=${GCFLAGS}"
    "-asmflags=${ASMFLAGS}" "-ldflags=${LDFLAGS}"
    ${_go_debug} ${_go_race} ${_go_buildmode}
    -mod=readonly
    -o "${OUTPUT}"
    "${PACKAGE}")
IF (NOT WIN32)
  # Golang very annoyingly leaves all downloaded module directories as
  # read-only, so not even rm -rf works. Go 1.14 introduces a new flag
  # GOFLAGS=-modcacherw which fixes this, but until we have switched
  # entirely to 1.14 or higher, here's a work-around. Note we suppress
  # and ignore any errors; this is just a convenience, so if it fails
  # we don't want to fail the build.
  EXECUTE_PROCESS (
    COMMAND find "${GO_BINARY_DIR}/pkg/mod" -type d -print0
    COMMAND xargs -0 chmod u+w
    OUTPUT_QUIET ERROR_QUIET
    RESULT_VARIABLE _ignored
  )
ENDIF ()
IF (CB_GO_CODE_COVERAGE)
  EXECUTE_PROCESS (
    COMMAND "${GOEXE}" test
      -c -cover -covermode=count -coverpkg ${PACKAGE}
      "-tags=${GOTAGS}" "-gcflags=${GCFLAGS}"
      "-asmflags=${ASMFLAGS}" "-ldflags=${LDFLAGS}"
      ${_go_debug}
      "${PACKAGE}")
ENDIF ()

IF (_failure)
  MESSAGE (FATAL_ERROR "Failed running go build")
ENDIF (_failure)
