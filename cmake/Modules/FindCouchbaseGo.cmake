# This module provides facilities for building Go code.
#
# The Couchbase build utilizes several different versions of the Go compiler
# in the production builds. The GoInstall() and GoYacc() macros have an
# option GOVERSION argument which allows individual targets to specify the
# version of Go they request / require.
#
# The build can work in two modes: a "multi-go" mode or a "single-go" mode.
#
# MULTI-GO MODE
# In "multi-go" mode, the build will download exactly the required versions of
# the Go compiler. The build will fail if the exact Go versions cannot be
# obtained, and it will not search for Go anywhere else.
# This is how the production builds work.
#
#   NOTE: the build can only support a single Go 1.4.x version safely due to
#   limitations in the Go compiler's ability to specify where to output
#   compiled artifacts. To ensure that all components throughout the build
#   that need Go 1.4 use the same version, you should specify
#   "GOVERSION 1.4.x". The specific version this corresponds to is defined
#   in this file by the variable GO_14x_VERSION. Any attempt to specify
#   a specific 1.4 version will raise an error.
#
# SINGLE-GO MODE
# In "single-go" mode, the build only expects to find a single Go compiler
# on the PATH, CMAKE_PREFIX_PATH, or similar. In this case, there is a global
# GO_MINIMUM_VERSION which is checked at configuration time against the
# actual compiler which was found. Also, if a target specifies a GOVERSION
# argument that is *higher* than the version found, the build will also fail.
# In this mode, an exact match for GOVERSION is not required.
#
# Multi-go is enabled by default. To disable it, set the CMake variable
# CB_MULTI_GO to any false value (or set the same-named environment variable).



# Prevent double-definition if two projects use this script
IF (NOT FindCouchbaseGo_INCLUDED)

  SET (CB_GO_CODE_COVERAGE 0 CACHE BOOL "Whether to use Go code coverage")
  SET (CB_GO_RACE_DETECTOR 0 CACHE BOOL "Whether to add race detector flag while generating go binaries")

  IF (DEFINED ENV{GOBIN})
    MESSAGE (FATAL_ERROR "The environment variable GOBIN is set. "
      "This will break the Couchbase build. Please unset it and re-build.")
  ENDIF (DEFINED ENV{GOBIN})

  INCLUDE (ParseArguments)

  # Have to remember cwd when this find is INCLUDE()d
  SET (TLM_MODULES_DIR "${CMAKE_CURRENT_LIST_DIR}")

  # This macro is called if Multi-Go mode is not enabled is not set. It will
  # find a single version of Go on the PATH and sets GO_SINGLE_EXECUTABLE and
  # GO_SINGLE_ROOT.
  MACRO (FIND_SINGLE_GO)

    # This is actually not accurate - Go 1.5 is required for some components.
    # But we can't bump this up until all production builds are off Sherlock-
    # class build slaves.
    SET(GO_MINIMUM_VERSION 1.4)

    # Find go compiler on the PATH
    FIND_PROGRAM (GO_SINGLE_EXECUTABLE NAMES go DOC "Go executable")
    IF (GO_SINGLE_EXECUTABLE)
      EXECUTE_PROCESS (COMMAND ${GO_SINGLE_EXECUTABLE} version
                       OUTPUT_VARIABLE GO_VERSION_STRING)
      STRING (REGEX REPLACE "^go version go([0-9.]+).*$" "\\1" GO_VERSION ${GO_VERSION_STRING})
      # I've seen cases where the version contains a trailing newline
      STRING(STRIP "${GO_VERSION}" GO_VERSION)
      MESSAGE (STATUS "Found Go compiler: ${GO_SINGLE_EXECUTABLE} (${GO_VERSION})")

      IF (GO_VERSION VERSION_LESS GO_MINIMUM_VERSION)
        STRING (REGEX MATCH "^go version devel .*" go_dev_version "${GO_VERSION}")
        IF (go_dev_version)
          MESSAGE(STATUS "WARNING: You are using a development version of go")
          MESSAGE(STATUS "         Go version of ${GO_MINIMUM_VERSION} or higher required")
          MESSAGE(STATUS "         You may experience problems caused by this")
        ELSE (go_dev_version)
          MESSAGE (FATAL_ERROR "Go version of ${GO_MINIMUM_VERSION} or higher required (found version ${GO_VERSION})")
        ENDIF (go_dev_version)
      ENDIF(GO_VERSION VERSION_LESS GO_MINIMUM_VERSION)

      EXECUTE_PROCESS (COMMAND "${GO_SINGLE_EXECUTABLE}" env GOROOT
        OUTPUT_VARIABLE GO_SINGLE_ROOT OUTPUT_STRIP_TRAILING_WHITESPACE)

    ELSE (GO_SINGLE_EXECUTABLE)
      MESSAGE (FATAL_ERROR "Go compiler not found!")
    ENDIF (GO_SINGLE_EXECUTABLE)
  ENDMACRO (FIND_SINGLE_GO)

  # This macro is called if Multi-Go mode is selected.
  MACRO (ENABLE_MULTI_GO)
    MESSAGE (STATUS "Multi-Go mode enabled; all desired Go compiler versions "
      "will be downloaded for the build")
    INCLUDE (CBDownloadDeps)
    SET (GO_14x_VERSION 1.4.2)
    IF (${CMAKE_SYSTEM_NAME} STREQUAL "FreeBSD")
      # 1.4.2 is not available for FreeBSD, but 1.4.3 is.
      # 1.4.3 cannot be default, because darwin build is missing.
      SET (GO_14x_VERSION 1.4.3)
    ENDIF ()

    # No compiler yet
    SET (GO_SINGLE_EXECUTABLE)
    SET (GO_SINGLE_ROOT)
  ENDMACRO (ENABLE_MULTI_GO)

  # On MacOS, to ensure compatibility with MacOS Sierra, we must enforce
  # a minimum version of Go. MB-20509.
  SET (GO_MAC_MINIMUM_VERSION 1.7.1)

  # This macro is called by GoInstall() / GoYacc() / etc. to find the
  # appropriate Go compiler to use, based on whether or not Multi-Go mode
  # is enabled and the requested version. It will set the variable named by
  # "var" to the full path of the corresponding GOROOT, or raise an error
  # if the requested version cannot be found. It will set the variable named
  # by "ver" to the actual version of Go used.
  MACRO (GET_GOROOT VERSION var ver)
    IF (CB_MULTI_GO)
      SET (_version ${VERSION})

      # Ensure no attempt to use a specific 1.4.
      IF ("${_version}" MATCHES "^1.4.[0-9]+$")
        MESSAGE (FATAL_ERROR "Cannot specify GOVERSION ${_version}; "
          "use only '1.4.x'")
      ENDIF ()

      # Map '1.4.x' special version to global default
      IF ("${_version}" STREQUAL "1.4.x")
        SET (_version "${GO_14x_VERSION}")
      ENDIF ()

      # MB-20509: MacOS Sierra requires a minimum of Go 1.7.1
      IF (APPLE)
        IF (${_version} VERSION_LESS "${GO_MAC_MINIMUM_VERSION}")
          IF ("$ENV{CB_MAC_GO_WARNING}" STREQUAL "")
            MESSAGE (${_go_warning} "Forcing Go version ${GO_MAC_MINIMUM_VERSION} on MacOS (MB-20509) "
              "(to suppress this warning, set environment variable "
              "CB_MAC_GO_WARNING to any value")
            SET (_go_warning WARNING)
          ENDIF ()
          SET (_version ${GO_MAC_MINIMUM_VERSION})
        ENDIF ()
      ENDIF ()

      GET_GO_VERSION ("${_version}" ${var})
      SET (${ver} ${_version})

    ELSE (CB_MULTI_GO)
      # QQQ For now just ignore the requested Go version since only one is
      # available. We should do a version check compared to the Go version
      # which was found to ensure it is equal or greater than the requested
      # version.

      # Return the constant values.
      SET (${var} "${GO_SINGLE_ROOT}")
      SET (${ver} "${GO_VERSION}")
    ENDIF (CB_MULTI_GO)
  ENDMACRO (GET_GOROOT)

  # Switch here between two types of find-go behaviour (see file header
  # comment)
  IF (DEFINED ENV{CB_MULTI_GO})
    SET (_multi_go $ENV{CB_MULTI_GO})
  ELSE ()
    SET (_multi_go 1)
  ENDIF ()
  SET (CB_MULTI_GO "${_multi_go}" CACHE BOOL "CB Multi-go behaviour")
  IF (CB_MULTI_GO)
    ENABLE_MULTI_GO ()
  ELSE ()
    FIND_SINGLE_GO ()
  ENDIF ()

  # Set up clean targets. Note: the hardcoded godeps and goproj is kind of
  # a hack; it should build that up from the GOPATHs passed to GoInstall.
  # Also, the pkg directories are only necessary for Go 1.4.x support since
  # all 1.5+ go artifacts are redirected to GO_BINARY_DIR.
  SET (GO_BINARY_DIR "${CMAKE_BINARY_DIR}/gopkg")
  ADD_CUSTOM_TARGET (go_realclean
    COMMAND "${CMAKE_COMMAND}" -E remove_directory "${GO_BINARY_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E remove_directory "${CMAKE_SOURCE_DIR}/godeps/pkg"
    COMMAND "${CMAKE_COMMAND}" -E remove_directory "${CMAKE_SOURCE_DIR}/godeps/bin"
    COMMAND "${CMAKE_COMMAND}" -E remove_directory "${CMAKE_SOURCE_DIR}/goproj/pkg"
    COMMAND "${CMAKE_COMMAND}" -E remove_directory "${CMAKE_SOURCE_DIR}/goproj/bin")
  ADD_DEPENDENCIES (realclean go_realclean)

  # Adds a target named TARGET which (always) calls "go install
  # PACKAGE".  This delegates incremental-build responsibilities to
  # the go compiler, which is generally what you want.
  #
  # Required arguments:
  #
  # TARGET - name of CMake target to create
  #
  # PACKAGE - A single Go package to build. When this is specified,
  # the package and all dependencies on GOPATH will be built, using
  # the Go compiler's normal dependency-handling system.
  #
  # GOPATH - Every entry on this list will be placed onto the GOPATH
  # environment variable before invoking the compiler.
  #
  # GOVERSION - the version of the Go compiler required for this target.
  # See file header comment.
  #
  # Optional arguments:
  #
  # GCFLAGS - flags that will be passed (via -gcflags) to all compile
  # steps; should be a single string value, with spaces if necessary
  #
  # GOTAGS - tags that will be passed (viga -tags) to all compile
  # steps; should be a single string value, with spaces as necessary
  #
  # LDFLAGS - flags that will be passed (via -ldflags) to all compile
  # steps; should be a single string value, with spaces if necessary
  #
  # NOCONSOLE - for targets that should not launch a console at runtime
  # (on Windows - silently ignored on other platforms)
  #
  # DEPENDS - list of other CMake targets on which TARGET will depend
  #
  # INSTALL_PATH - if specified, a CMake INSTALL() directive will be
  # created to install the output into the named path
  #
  # OUTPUT - name of the installed executable (only applicable if
  # INSTALL_PATH is specified). Default value is the basename of
  # PACKAGE, per the go compiler. On Windows, ".exe" will be
  # appended.
  #
  # CGO_INCLUDE_DIRS - path(s) to directories to search for C include files
  #
  # CGO_LIBRARY_DIRS - path(s) to libraries to search for C link libraries
  #
  MACRO (GoInstall)

    PARSE_ARGUMENTS (Go "DEPENDS;GOPATH;CGO_INCLUDE_DIRS;CGO_LIBRARY_DIRS"
      "TARGET;PACKAGE;OUTPUT;INSTALL_PATH;GOVERSION;GCFLAGS;GOTAGS;LDFLAGS"
      "NOCONSOLE" ${ARGN})

    IF (NOT Go_TARGET)
      MESSAGE (FATAL_ERROR "TARGET is required!")
    ENDIF (NOT Go_TARGET)
    IF (NOT Go_PACKAGE)
      MESSAGE (FATAL_ERROR "PACKAGE is required!")
    ENDIF (NOT Go_PACKAGE)
    IF (NOT Go_GOVERSION)
      MESSAGE (FATAL_ERROR "GOVERSION is required!")
    ENDIF (NOT Go_GOVERSION)

    # Hunt for the requested package on GOPATH (used for installing)
    SET (_found)
    FOREACH (_dir ${Go_GOPATH})
      FILE (TO_NATIVE_PATH "${_dir}/src/${Go_PACKAGE}" _pkgdir)
      IF (IS_DIRECTORY "${_pkgdir}")
        SET (_found 1)
        SET (_workspace "${_dir}")
        BREAK ()
      ENDIF (IS_DIRECTORY "${_pkgdir}")
    ENDFOREACH (_dir)
    IF (NOT _found)
      MESSAGE (FATAL_ERROR "Package ${Go_PACKAGE} not found in any workspace on GOPATH!")
    ENDIF (NOT _found)

    # Extract the binary name from the package, and tweak for Windows.
    GET_FILENAME_COMPONENT (_pkgexe "${Go_PACKAGE}" NAME)
    IF (WIN32)
      SET (_pkgexe "${_pkgexe}.exe")
    ENDIF (WIN32)
    IF (Go_OUTPUT)
      IF (WIN32)
        SET (Go_OUTPUT "${Go_OUTPUT}.exe")
      ENDIF (WIN32)
    ENDIF (Go_OUTPUT)

    # Concatenate NOCONSOLE with LDFLAGS
    IF (WIN32 AND ${Go_NOCONSOLE})
      SET (_ldflags "-H windowsgui ${Go_LDFLAGS}")
    ELSE (WIN32 AND ${Go_NOCONSOLE})
      SET (_ldflags "${Go_LDFLAGS}")
    ENDIF (WIN32  AND ${Go_NOCONSOLE})

    # Compute path to Go compiler, depending on the Go mode (single or multi)
    GET_GOROOT ("${Go_GOVERSION}" _goroot _gover)

    # Go install target
    ADD_CUSTOM_TARGET ("${Go_TARGET}" ALL
      COMMAND "${CMAKE_COMMAND}"
      -D "GOROOT=${_goroot}"
      -D "GOVERSION=${_gover}"
      -D "GO_BINARY_DIR=${GO_BINARY_DIR}/go-${_gover}"
      -D "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
      -D "GOPATH=${Go_GOPATH}"
      -D "WORKSPACE=${_workspace}"
      -D "CGO_LDFLAGS=${CMAKE_CGO_LDFLAGS}"
      -D "GCFLAGS=${Go_GCFLAGS}"
      -D "GOTAGS=${Go_GOTAGS}"
      -D "LDFLAGS=${_ldflags}"
      -D "PKGEXE=${_pkgexe}"
      -D "PACKAGE=${Go_PACKAGE}"
      -D "OUTPUT=${Go_OUTPUT}"
      -D "CGO_INCLUDE_DIRS=${Go_CGO_INCLUDE_DIRS}"
      -D "CGO_LIBRARY_DIRS=${Go_CGO_LIBRARY_DIRS}"
      -D "CB_GO_CODE_COVERAGE=${CB_GO_CODE_COVERAGE}"
      -D "CB_GO_RACE_DETECTOR=${CB_GO_RACE_DETECTOR}"
      -P "${TLM_MODULES_DIR}/go-install.cmake"
      COMMENT "Building Go target ${Go_TARGET} using Go ${_gover}"
      VERBATIM)
    IF (Go_DEPENDS)
      ADD_DEPENDENCIES (${Go_TARGET} ${Go_DEPENDS})
    ENDIF (Go_DEPENDS)
    MESSAGE (STATUS "Added Go build target '${Go_TARGET}' using Go ${_gover}")

    # We expect multiple go targets to be operating over the same
    # GOPATH.  It seems like the go compiler doesn't like be invoked
    # in parallel in this case, as would happen if we parallelize the
    # Couchbase build (eg., 'make -j8'). Since the go compiler itself
    # does parallel building, we want to serialize all go targets. So,
    # we make them all depend on any earlier Go targets.
    GET_PROPERTY (_go_targets GLOBAL PROPERTY CB_GO_TARGETS)
    IF (_go_targets)
      ADD_DEPENDENCIES(${Go_TARGET} ${_go_targets})
    ENDIF (_go_targets)
    SET_PROPERTY (GLOBAL APPEND PROPERTY CB_GO_TARGETS ${Go_TARGET})

    # Tweaks for installing and output renaming. go-install.cmake will
    # arrange for the workspace's bin directory to contain a file with
    # the right name (either OUTPUT, or the Go package name if OUTPUT
    # is not specified). We need to know what that name is so we can
    # INSTALL() it.
    IF (Go_OUTPUT)
      SET (_finalexe "${Go_OUTPUT}")
    ELSE (Go_OUTPUT)
      SET (_finalexe "${_pkgexe}")
    ENDIF (Go_OUTPUT)
    IF (Go_INSTALL_PATH)
      INSTALL (PROGRAMS "${_workspace}/bin/${_finalexe}"
        DESTINATION "${Go_INSTALL_PATH}")
    ENDIF (Go_INSTALL_PATH)

  ENDMACRO (GoInstall)


  # Adds a target named TARGET which (always) calls "go tool yacc
  # PATH".
  #
  # Required arguments:
  #
  # TARGET - name of CMake target to create
  #
  # YFILE - Absolute path to .y file.
  #
  # Optional arguments:
  #
  # DEPENDS - list of other CMake targets on which TARGET will depend
  #
  # GOVERSION - the version of the Go compiler required for this target.
  # See file header comment.
  #
  MACRO (GoYacc)

    PARSE_ARGUMENTS (Go "DEPENDS" "TARGET;YFILE;GOVERSION" "" ${ARGN})

    IF (NOT Go_TARGET)
      MESSAGE (FATAL_ERROR "TARGET is required!")
    ENDIF (NOT Go_TARGET)
    IF (NOT Go_YFILE)
      MESSAGE (FATAL_ERROR "YFILE is required!")
    ENDIF (NOT Go_YFILE)

    GET_FILENAME_COMPONENT (_ypath "${Go_YFILE}" PATH)
    GET_FILENAME_COMPONENT (_yfile "${Go_YFILE}" NAME)

    SET(Go_OUTPUT "${_ypath}/y.go")

    # Compute path to Go compiler, depending on the Go mode (single or multi)
    GET_GOROOT ("${Go_GOVERSION}" _goroot _gover)

    ADD_CUSTOM_COMMAND(OUTPUT "${Go_OUTPUT}"
                       COMMAND "${CMAKE_COMMAND}"
                       -D "GOROOT=${_goroot}"
                       -D "YFILE=${_yfile}"
                       -P "${TLM_MODULES_DIR}/go-yacc.cmake"
                       DEPENDS ${Go_YFILE}
                       WORKING_DIRECTORY "${_ypath}"
                       COMMENT "Build Go yacc target ${Go_TARGET} using Go ${_gover}"
                       VERBATIM)

    ADD_CUSTOM_TARGET ("${Go_TARGET}"
                       DEPENDS "${Go_OUTPUT}")
    MESSAGE (STATUS "Added Go yacc target '${Go_TARGET}' using Go ${_gover}")

    IF (Go_DEPENDS)
      ADD_DEPENDENCIES (${Go_TARGET} ${Go_DEPENDS})
    ENDIF (Go_DEPENDS)

  ENDMACRO (GoYacc)

  SET (FindCouchbaseGo_INCLUDED 1)

ENDIF (NOT FindCouchbaseGo_INCLUDED)
