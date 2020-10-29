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

# Set GO111MODULE to "off" since we're by definition not building with modules
SET (ENV{GO111MODULE} "off")

# Use -pkgdir to separate the compiled bits out
# of the source directories - separate directories per Go version, to
# prevent conflicts.
SET (_bits -pkgdir "${GO_BINARY_DIR}")
STRING (REPLACE ";" " " _bits_str "${_bits}")

# Attempt to hide build-system-specific paths in resulting binaries.
get_filename_component(REPOSYNC "${REPOSYNC}" REALPATH)
SET (GCFLAGS "-trimpath=${REPOSYNC}" ${GCFLAGS})
SET (ASMFLAGS "-trimpath=${REPOSYNC}")

# Execute "go install".
IF (DEFINED ENV{VERBOSE})
  MESSAGE (STATUS "Executing: \"${GO_EXECUTABLE}\" install ${_bits_str} \"-tags=${GOTAGS}\" \"-gcflags=${GCFLAGS}\" \"-asmflags=${ASMFLAGS}\" \"-ldflags=${LDFLAGS}\" ${_go_debug} ${_go_race} \"${PACKAGE}\"")
endif()
EXECUTE_PROCESS (RESULT_VARIABLE _failure
  COMMAND "${GO_EXECUTABLE}" install ${_bits} "-tags=${GOTAGS}" "-gcflags=${GCFLAGS}" "-asmflags=${ASMFLAGS}" "-ldflags=${LDFLAGS}" ${_go_debug} ${_go_race} "${PACKAGE}")
  IF (CB_GO_CODE_COVERAGE)
    MESSAGE (STATUS "Executing: ${GO_EXECUTABLE} test -c -cover -covermode=count -coverpkg ${PACKAGE} -tags=${GOTAGS} -gcflags=${GCFLAGS} -asmflags=${ASMFLAGS} -ldflags=${LDFLAGS} ${_go_debug} ${PACKAGE}")
    EXECUTE_PROCESS (COMMAND "${GO_EXECUTABLE}" test -c -cover -covermode=count -coverpkg ${PACKAGE} "-tags=${GOTAGS}" "-gcflags=${GCFLAGS}" "-asmflags=${ASMFLAGS}" "-ldflags=${LDFLAGS}" ${_go_debug} "${PACKAGE}")
  ENDIF ()
IF (_failure)
  MESSAGE (STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
  MESSAGE (STATUS "@ 'go install' failed! Re-running as 'go build' to help debug...")
  MESSAGE (STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
  # Easier to debug
  EXECUTE_PROCESS (COMMAND "${GO_EXECUTABLE}" build ${_bits} "-tags=${GOTAGS}" "-gcflags=${GCFLAGS}" "-asmflags=${ASMFLAGS}" "-ldflags=${LDFLAGS}" -x "${PACKAGE}")
  MESSAGE (FATAL_ERROR "Failed running go install")
ENDIF (_failure)

# If OUTPUT is set, rename the final output binary to the desired
# name.  This messes with "go install"'s incremental build logic, but
# is unavoidable.
IF (OUTPUT)
  EXECUTE_PROCESS (COMMAND "${CMAKE_COMMAND}" -E copy_if_different
  "${WORKSPACE}/bin/${PKGEXE}" "${WORKSPACE}/bin/${OUTPUT}")
ENDIF (OUTPUT)
