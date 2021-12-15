# Convert GOPATH list, if set, to proper GOPATH environment variable.
# Otherwise we'll inherit the caller's GOPATH environment.
IF (GOPATH)
  SET (_gopath "${GOPATH}")
  IF (NOT WIN32)
    STRING (REPLACE ";" ":" _gopath "${_gopath}")
  ENDIF (NOT WIN32)
  SET (ENV{GOPATH} "${_gopath}")
ENDIF (GOPATH)

MACRO (EXPORT_FLAGS var envvar flag)
  IF (${var})
    SET (_value)
    FOREACH (_dir ${${var}})
      SET (_value "${_value} ${flag} ${_dir}")
    ENDFOREACH (_dir)
    SET (ENV{${envvar}} "${_value}")
  ENDIF (${var})
ENDMACRO (EXPORT_FLAGS)

# Convert CGO_xxx_DIRS values into platform- and compiler-appropriate
# CGO_ environment variables. Currently only known to work on Linux
# and probably Mac environments.
EXPORT_FLAGS (CGO_INCLUDE_DIRS CGO_CPPFLAGS "-I")
EXPORT_FLAGS (CGO_LIBRARY_DIRS CGO_LDFLAGS "-L")

IF (CGO_LDFLAGS)
   SET (ENV{CGO_LDFLAGS} "$ENV{CGO_LDFLAGS} ${CGO_LDFLAGS}")
ENDIF ()

IF (NOT WIN32 AND NOT APPLE)
  IF (CB_THREADSANITIZER OR CB_ADDRESSSANITIZER OR CB_UNDEFINEDSANITIZER)
    # Only use the CMAKE C compiler for cgo on non-Windows platforms;
    # on Windows we use a different compiler (gcc) for cgo than for
    # the main build MSVC).
    # On macOS, Golang fails with "_cgo_export.c:3:10: fatal error:
    # 'stdlib.h' file not found" if we override CC to be
    # CMAKE_C_COMPILER (which is 'cc' by default), using Golang's
    # default of 'clang' is fine hence also skip the override here.
    SET (ENV{CC} "${CMAKE_C_COMPILER}")
  ENDIF (CB_THREADSANITIZER OR CB_ADDRESSSANITIZER OR CB_UNDEFINEDSANITIZER)
ENDIF()

# QQQ TOTAL HACK to enable CGO binaries to find Couchbase-built shared
# libraries.  This will clearly only work on Linux ELF-based systems,
# and only for those libraries which are installed in the correct path
# relative to the installed location of the Go executable. I'm still
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

# Set GOROOT environment
SET (ENV{GOROOT} "${GOROOT}")
SET (GO_EXECUTABLE "${GOROOT}/bin/go")

# For Go 1.5 or better, use -pkgdir to separate the compiled bits out
# of the source directories - separate directories per Go version, to
# prevent conflicts.
SET (_bits)
IF ("${GOVERSION}" VERSION_GREATER 1.4.9)
  SET (_bits -pkgdir "${GO_BINARY_DIR}")
  STRING (REPLACE ";" " " _bits_str "${_bits}")
ENDIF ()

# The test needs to know where to find the shared libraries created during the
# build. So add them to LD_LIBRARY_PATH here and give them priority.
SET(ENV{LD_LIBRARY_PATH} "${CGO_LIBRARY_DIRS}:$ENV{LD_LIBRARY_PATH}")

# Execute "go test".
MESSAGE (STATUS "Executing: ${GO_EXECUTABLE} test ${_bits_str} -tags=\"${GOTAGS}\" -gcflags=\"${GCFLAGS}\" -ldflags=\"${LDFLAGS}\" ${_go_debug} ${_go_race} ${PACKAGE}")
EXECUTE_PROCESS (RESULT_VARIABLE _failure
  COMMAND "${GO_EXECUTABLE}" test ${_bits} "-tags=${GOTAGS}" "-gcflags=${GCFLAGS}" "-ldflags=${LDFLAGS}" ${_go_debug} ${_go_race} "${PACKAGE}")
  IF (CB_GO_CODE_COVERAGE)
    MESSAGE (STATUS "Executing: ${GO_EXECUTABLE} test -c -cover -covermode=count -coverpkg ${PACKAGE} -tags=${GOTAGS} -gcflags=${GCFLAGS} -ldflags=${LDFLAGS} ${_go_debug} ${PACKAGE}")
    EXECUTE_PROCESS (COMMAND "${GO_EXECUTABLE}" test -c -cover -covermode=count -coverpkg ${PACKAGE} "-tags=${GOTAGS}" "-gcflags=${GCFLAGS}" "-ldflags=${LDFLAGS}" ${_go_debug} "${PACKAGE}")
  ENDIF ()
IF (_failure)
  MESSAGE (FATAL_ERROR "Failed running go test")
ENDIF (_failure)
