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

# Unset GOROOT in the environment (which will make Go figure it out from
# the path to the go compiler on disk, which is what we want)
SET (ENV{GOROOT})

# Use GOPATH to tell Go where to store downloaded and cached Go modules.
# It will put things into pkg/mod.
IF (WIN32)
  SET (ENV{GOPATH} "$ENV{HOMEDRIVE}/$ENV{HOMEPATH}/cbdepscache/gomodcache")
ELSE ()
  SET (ENV{GOPATH} "$ENV{HOME}/.cbdepscache/gomodcache")
ENDIF ()

# Set GO111MODULE since we're by definition building with modules (just in
# case it's set to a bad value in the environment)
SET (ENV{GO111MODULE} "on")

# Use GOCACHE to tell Go where to store intermediate compilation artifacts.
# It places things directly into this directory, so we append /cache.
SET (ENV{GOCACHE} "${GO_BINARY_DIR}/cache")

# If this is a production build, set/override GOPROXY.
# (For now, not on AWS since it doesn't have access to our proxy.)
IF (CB_PRODUCTION_BUILD AND NOT EXISTS "/aws")
  SET (ENV{GOPROXY} "http://goproxy.build.couchbase.com/")
ENDIF ()

# Attempt to hide build-system-specific paths in resulting binaries.
get_filename_component(REPOSYNC "${REPOSYNC}" REALPATH)
SET (GCFLAGS "-trimpath=${REPOSYNC}" ${GCFLAGS})
SET (ASMFLAGS "-trimpath=${REPOSYNC}")

IF (DEFINED ENV{VERBOSE})
  SET (CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)
ENDIF ()

# Golang very annoyingly leaves all downloaded module directories as
# read-only, so not even rm -rf works. Go 1.14 introduces a new flag
# GOFLAGS=-modcacherw which fixes this
IF (${GOVERSION} VERSION_GREATER_EQUAL 1.14)
  SET (_go_rw_modcache -modcacherw)
ENDIF ()

# Execute "go build".
EXECUTE_PROCESS (
  RESULT_VARIABLE _failure
  OUTPUT_VARIABLE _output
  ERROR_VARIABLE _output
  COMMAND "${GOEXE}" build
    "-tags=${GOTAGS}" "-gcflags=${GCFLAGS}"
    "-asmflags=${ASMFLAGS}" "-ldflags=${LDFLAGS}"
    ${_go_debug} ${_go_race} ${_go_rw_modcache}
    -mod=readonly
    -o "${OUTPUT}"
    "${PACKAGE}")

# For go versions 1.13 or lower, here's a work-around for the read-only
# cache issue. Note we suppress and ignore any errors; this is just a
# convenience, so if it fails we don't want to fail the build.
IF (NOT WIN32 AND NOT _go_rw_modcache)
  EXECUTE_PROCESS (
    COMMAND find "$ENV{GOPATH}/pkg/mod" -type d -print0
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
  MESSAGE ("Error running go build for package ${PACKAGE}!\n${_output}")
  MESSAGE (FATAL_ERROR "Failed running go modules build for package ${PACKAGE}")
ENDIF (_failure)
