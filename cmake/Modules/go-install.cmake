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

# QQQ TOTAL HACK to enable CGO binaries to find Couchbase-built shared
# libraries.  This will clearly only work on Linux ELF-based systems,
# and only for those libraries which are installed in the correct path
# relative to the installed location of the Go executable. I'm still
# trying to figure out how to handle this correctly.
SET (ENV{LD_RUN_PATH} "$ORIGIN/../lib")

# Execute "go install"
MESSAGE (STATUS "Executing: ${GO_EXECUTABLE} install -x ${PACKAGE}")
EXECUTE_PROCESS (RESULT_VARIABLE _failure
  COMMAND "${GO_EXECUTABLE}" install -x "${PACKAGE}")
IF (_failure)
  MESSAGE (FATAL_ERROR "Failed running go install")
ENDIF (_failure)

# If OUTPUT is set, rename the final output binary to the desired
# name.  This messes with "go install"'s incremental build logic, but
# is unavoidable.
IF (OUTPUT)
  FILE (RENAME "${WORKSPACE}/bin/${PKGEXE}" "${WORKSPACE}/bin/${OUTPUT}")
ENDIF (OUTPUT)
