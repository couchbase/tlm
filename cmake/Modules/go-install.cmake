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

# Convert CMake semicolon-separated lists into space-separated strings
# for passing CGO flags via environment.
IF (CGO_CFLAGS)
  STRING(REPLACE ";" " " _cgo_cflags "${CGO_CFLAGS}")
  SET (ENV{CGO_CFLAGS} "$ENV{CGO_CFLAGS} ${_cgo_cflags}")
ENDIF ()

IF (CGO_LDFLAGS)
  STRING(REPLACE ";" " " _cgo_ldflags "${CGO_LDFLAGS}")
  SET (ENV{CGO_LDFLAGS} "$ENV{CGO_LDFLAGS} ${_cgo_ldflags}")
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

# Our globally-desired RPATH for all Go executables (so far anyway)
# for Linux and MacOS. Windows doesn't have a problem currently
# because all exes and libs get dumped together.
IF (APPLE)
  SET (ENV{CGO_LDFLAGS} "$ENV{CGO_LDFLAGS} -Wl,-rpath,@executable_path/../lib")
ELSEIF (UNIX)
  # UNIX but not APPLE == LINUX
  SET (ENV{CGO_LDFLAGS} "$ENV{CGO_LDFLAGS} -Wl,-rpath=$ORIGIN/../lib")
ENDIF ()

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
  SET (CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)
endif()
EXECUTE_PROCESS (RESULT_VARIABLE _failure
  COMMAND "${GO_EXECUTABLE}" install ${_bits} "-tags=${GOTAGS}" "-gcflags=${GCFLAGS}" "-asmflags=${ASMFLAGS}" "-ldflags=${LDFLAGS}" ${_go_debug} ${_go_race} "${PACKAGE}")
  IF (CB_GO_CODE_COVERAGE)
    EXECUTE_PROCESS (COMMAND "${GO_EXECUTABLE}" test -c -cover -covermode=count -coverpkg ${PACKAGE} "-tags=${GOTAGS}" "-gcflags=${GCFLAGS}" "-asmflags=${ASMFLAGS}" "-ldflags=${LDFLAGS}" ${_go_debug} "${PACKAGE}")
  ENDIF ()
IF (_failure)
  MESSAGE (STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
  MESSAGE (STATUS "@ 'go install' failed for package ${PACKAGE}! Re-running as 'go build' to help debug...")
  MESSAGE (STATUS "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
  # Easier to debug - always have command echo here
  SET (CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)
  EXECUTE_PROCESS (COMMAND "${GO_EXECUTABLE}" build ${_bits} "-tags=${GOTAGS}" "-gcflags=${GCFLAGS}" "-asmflags=${ASMFLAGS}" "-ldflags=${LDFLAGS}" -x "${PACKAGE}")
  MESSAGE (FATAL_ERROR "Failed running go install for package ${PACKAGE}")
ENDIF (_failure)

# If OUTPUT is set, rename the final output binary to the desired
# name.  This messes with "go install"'s incremental build logic, but
# is unavoidable.
IF (OUTPUT)
  EXECUTE_PROCESS (COMMAND "${CMAKE_COMMAND}" -E copy_if_different
  "${WORKSPACE}/bin/${PKGEXE}" "${WORKSPACE}/bin/${OUTPUT}")
ENDIF (OUTPUT)
