# This module provides facilities for building Go code.
#
# The Couchbase build utilizes several different versions of the Go compiler
# in the production builds. The GoInstall() and GoYacc() macros have an
# option GOVERSION argument which allows individual targets to specify the
# version of Go they request / require.

# Prevent double-definition if two projects use this script
IF (NOT FindCouchbaseGo_INCLUDED)

  ###################################################################
  # THINGS YOU MAY NEED TO UPDATE OVER TIME

  # On MacOS, we frequently need to enforce a newer version of Go.
  SET (GO_MAC_MINIMUM_VERSION 1.17)

  # END THINGS YOU MAY NEED TO UPDATE OVER TIME
  ####################################################################

  SET (CB_GO_CODE_COVERAGE 0 CACHE BOOL "Whether to use Go code coverage")
  SET (CB_GO_RACE_DETECTOR 0 CACHE BOOL "Whether to add race detector flag while generating go binaries")

  IF (DEFINED ENV{GOBIN})
    MESSAGE (FATAL_ERROR "The environment variable GOBIN is set. "
      "This will break the Couchbase build. Please unset it and re-build.")
  ENDIF (DEFINED ENV{GOBIN})

  INCLUDE (ParseArguments)

  # Have to remember cwd when this find is INCLUDE()d
  SET (TLM_MODULES_DIR "${CMAKE_CURRENT_LIST_DIR}")

  # This macro is called by GoInstall() / GoYacc() / etc. to find the
  # appropriate Go compiler to use. It will set the variable named by
  # "var" to the full path of the corresponding GOROOT, or raise an error
  # if the requested version cannot be found. It will set the variable named
  # by "ver" to the actual version of Go used.
  MACRO (GET_GOROOT VERSION var ver)
    SET (_request_version ${VERSION})

    # MacOS often requires a newer Go version for $REASONS
    IF (APPLE)
      IF (${_request_version} VERSION_LESS "${GO_MAC_MINIMUM_VERSION}")
        IF ("$ENV{CB_MAC_GO_WARNING}" STREQUAL "")
          MESSAGE (${_go_warning} "Forcing Go version ${GO_MAC_MINIMUM_VERSION} on MacOS "
            "(to suppress this warning, set environment variable "
            "CB_MAC_GO_WARNING to any value")
          SET (_go_warning WARNING)
          SET (ENV{CB_MAC_GO_WARNING} true)
        ENDIF ()
        SET (_request_version ${GO_MAC_MINIMUM_VERSION})
      ENDIF ()
    ENDIF ()

    # Compute the major version from the requested version.
    # Transition: existing code specifies a complete Go version, eg. 1.18.4.
    # We want to trim that to a major version, eg. 1.18.
    STRING (REGEX MATCHALL "[0-9]+" _ver_bits "${_request_version}")
    LIST (LENGTH _ver_bits _num_ver_bits)
    IF (_num_ver_bits EQUAL 2)
      SET (_major_version "${_request_version}")
    ELSEIF (_num_ver_bits EQUAL 3)
      LIST (POP_BACK _ver_bits)
      LIST (JOIN _ver_bits "." _major_version)
      IF (NOT ${UNSHIPPED})
        MESSAGE (WARNING "Please change GOVERSION to ${_major_version}, not ${_request_version}")
      ENDIF ()
    ELSE ()
      MESSAGE (FATAL_ERROR "Illegal Go version ${_request_version}!")
    ENDIF ()

    # Map X.Y version to specific version for download for all shipped binaries
    SET (GOVER_FILE
      "${CMAKE_SOURCE_DIR}/golang/versions/${_major_version}.txt"
    )
    IF (NOT EXISTS "${GOVER_FILE}")
      IF (${UNSHIPPED})
        # Just revert to the originally-requested version
        MESSAGE (STATUS "Go version ${VERSION} is not supported, but using "
                 "anyway as target is unshipped (but consider upgrading)")
        SET (_ver_final "${VERSION}")
      ELSE ()
        MESSAGE (WARNING "Go version ${_request_version} no longer supported - forcing to 1.18.7")
        SET (_ver_final 1.18.7)
      ENDIF ()
    ELSE ()
      FILE (STRINGS "${GOVER_FILE}" _ver_final LIMIT_COUNT 1)
    ENDIF ()

    GET_GO_VERSION ("${_ver_final}" ${var})
    SET (${ver} ${_ver_final})
  ENDMACRO (GET_GOROOT)

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
        "TARGET;PACKAGE;OUTPUT;INSTALL_PATH;GOVERSION;GCFLAGS;GOTAGS;GOBUILDMODE;LDFLAGS"
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
    IF (NOT Go_GOBUILDMODE)
        SET(Go_GOBUILDMODE "default")
    ENDIF (NOT Go_GOBUILDMODE)

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

    # If Sanitizers are enabled then add a runtime linker path to
    # locate libasan.so / libubsan.so etc.
    # This isn't usually needed if we are running on the same machine
    # as we built (as the sanitizer libraries are typically in
    # /usr/lib/ or similar), however when creating a packaged build
    # which will be installed and run on a different machine we need
    # to ensure that the runtime linker knows how to find our copies
    # of libasan.so etc in $PREFIX/lib.
    IF (CB_ADDRESSSANITIZER OR CB_UNDEFINED_SANITIZER)
      SET (_ldflags "${_ldflags} -r \$ORIGIN/../lib")
    ENDIF()

    # Compute path to Go compiler
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
      -D "REPOSYNC=${TLM_MODULES_DIR}/../../.."
      -D "CGO_CFLAGS=${CMAKE_CGO_CFLAGS}"
      -D "CGO_LDFLAGS=${CMAKE_CGO_LDFLAGS}"
      -D "GCFLAGS=${Go_GCFLAGS}"
      -D "GOTAGS=${Go_GOTAGS}"
      -D "GOBUILDMODE=${Go_GOBUILDMODE}"
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

  # Adds a test named NAME which calls go test in the DIR
  # Required arguments:
  #
  # TARGET - name of the test to create
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
  # CGO_INCLUDE_DIRS - path(s) to directories to search for C include files
  #
  # CGO_LIBRARY_DIRS - path(s) to libraries to search for C link libraries
  #

  MACRO (GoTest)

  PARSE_ARGUMENTS (Go "DEPENDS;GOPATH;CGO_INCLUDE_DIRS;CGO_LIBRARY_DIRS"
      "TARGET;PACKAGE;GOVERSION;GCFLAGS;GOTAGS;GOBUILDMODE;LDFLAGS"
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
  IF (NOT Go_GOBUILDMODE)
      SET(Go_GOBUILDMODE default)
  ENDIF (NOT Go_GOBUILDMODE)

  # Concatenate NOCONSOLE with LDFLAGS
  IF (WIN32 AND ${Go_NOCONSOLE})
    SET (_ldflags "-H windowsgui ${Go_LDFLAGS}")
  ELSE (WIN32 AND ${Go_NOCONSOLE})
    SET (_ldflags "${Go_LDFLAGS}")
  ENDIF (WIN32  AND ${Go_NOCONSOLE})

  # Compute path to Go compiler
  GET_GOROOT ("${Go_GOVERSION}" _goroot _gover)

  add_test(NAME "${Go_TARGET}"
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
             -D "GOBUILDMODE=${Go_GOBUILDMODE}"
             -D "LDFLAGS=${_ldflags}"
             -D "PACKAGE=${Go_PACKAGE}"
             -D "CGO_INCLUDE_DIRS=${Go_CGO_INCLUDE_DIRS}"
             -D "CGO_LIBRARY_DIRS=${Go_CGO_LIBRARY_DIRS}"
             -D "CB_GO_CODE_COVERAGE=${CB_GO_CODE_COVERAGE}"
             -D "CB_GO_RACE_DETECTOR=${CB_GO_RACE_DETECTOR}"
             -P "${TLM_MODULES_DIR}/go-test.cmake")

  ENDMACRO (GoTest)

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

    # Only build this target if somebody uses this macro
    IF (NOT TARGET goyacc)
      GoInstall (TARGET goyacc
      PACKAGE golang.org/x/tools/cmd/goyacc
      GOVERSION 1.11
      GOPATH "${CMAKE_SOURCE_DIR}/godeps")
    ENDIF ()

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

    # Compute path to Go compiler
    GET_GOROOT ("${Go_GOVERSION}" _goroot _gover)

    ADD_CUSTOM_COMMAND(OUTPUT "${Go_OUTPUT}"
                       COMMAND "${CMAKE_COMMAND}"
                       -D "GOROOT=${_goroot}"
                       -D "GOYACC_EXECUTABLE=${CMAKE_SOURCE_DIR}/godeps/bin/goyacc"
                       -D "YFILE=${_yfile}"
                       -P "${TLM_MODULES_DIR}/go-yacc.cmake"
                       DEPENDS ${Go_YFILE} goyacc
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
