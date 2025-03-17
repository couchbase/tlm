# This module provides facilities for building Go code.
#
# The Couchbase build utilizes several different versions of the Go
# compiler in the production builds. The GoModBuild() and GoTest()
# macros have a GOVERSION argument which allows individual targets to
# specify the version of Go they request / require. This argument should
# take one of these forms:
#
#   SUPPORTED_OLDER, SUPPORTED_NEWER - at any point in time only two
#      major versions of Go are supported by Google. By specifying one
#      of these two constants, the code will be built using the older or
#      newer of these versions. Again the specific minor version used
#      will be determined by the centralized Go version management.
#
#   X.Y, eg. 1.19 (deprecated) - major Go version to use (specific minor
#      version used will be determined by the centralized Go version
#      management from the "golang" repository)
#
#   X.Y.Z, eg. 1.19.4 (deprecated) - this will be translated to X.Y with
#      a warning to update.

# Prevent double-definition if two projects use this script
IF (NOT FindCouchbaseGo_INCLUDED)

  ###################################################################
  # THINGS YOU MAY NEED TO UPDATE OVER TIME

  # On MacOS, we frequently need to enforce a newer version of Go.
  SET (GO_MAC_MINIMUM_VERSION 1.17)

  # List of private Go module paths that are missing when syncing
  # strictly the source-available projects.
  SET (GO_PRIVATE_MODULE_PATHS
    cbftx
    hebrew
    goproj/src/github.com/couchbase/bhive
    goproj/src/github.com/couchbase/eventing-ee
    goproj/src/github.com/couchbase/plasma
    goproj/src/github.com/couchbase/query-ee
    goproj/src/github.com/couchbase/regulator
  )

  # List of directories (relative to repo sync root) containing Go
  # modules that are only libraries - eg., don't have a CMakeLists.txt
  # of their own. This is used to create 'tidy' rules. The directories
  # in this list will be skipped if they don't exist, so it is safe to
  # include eg. private repositories.
  SET (GO_LIBRARY_MODULE_PATHS
    cbftx
    cbgt
    hebrew
    goproj/src/github.com/couchbase/bhive
    goproj/src/github.com/couchbase/godbc
    goproj/src/github.com/couchbase/gomemcached
    goproj/src/github.com/couchbase/n1fty
    goproj/src/github.com/couchbase/nitro
    goproj/src/github.com/couchbase/query-ee
    goproj/src/github.com/couchbase/regulator
    magma/tools/kvloader
  )

  # QQQ These should be removed as the corresponding projects are
  # updated to call GoModTidySetup() themselves
  SET (GO_LIBRARY_MODULE_PATHS_SOON
    backup
    goproj/src/github.com/couchbase/cbas
    goproj/src/github.com/couchbase/cbauth
    goproj/src/github.com/couchbase/eventing
    goproj/src/github.com/couchbase/eventing-ee
    goproj/src/github.com/couchbase/gometa
    goproj/src/github.com/couchbase/indexing
    goproj/src/github.com/couchbase/plasma
    goproj/src/github.com/couchbase/query
    goproj/src/github.com/couchbase/xdcrDiffer
    ns_server/deps/gocode
  )

  # END THINGS YOU MAY NEED TO UPDATE OVER TIME
  ####################################################################

  OPTION (CB_DWARF_HEADER_COMPRESSION "Enable DWARF header compression" ON)

  IF (CB_DEBUG_GO_TARGETS)
    INCLUDE (ListTargetProperties)
  ENDIF ()

  SET (CB_GO_CODE_COVERAGE 0 CACHE BOOL "Whether to use Go code coverage")
  SET (CB_GO_RACE_DETECTOR 0 CACHE BOOL "Whether to add race detector flag while generating go binaries")

  IF (DEFINED ENV{GOBIN})
    MESSAGE (FATAL_ERROR "The environment variable GOBIN is set. "
      "This will break the Couchbase build. Please unset it and re-build.")
  ENDIF (DEFINED ENV{GOBIN})

  INCLUDE (ParseArguments)
  INCLUDE (CBDownloadDeps)

  # Have to remember cwd when this file is INCLUDE()d
  SET (TLM_MODULES_DIR "${CMAKE_CURRENT_LIST_DIR}")
  # Create any 'private' module paths
  IF (NOT BUILD_ENTERPRISE)
    FOREACH (PRIV_PATH ${GO_PRIVATE_MODULE_PATHS})
      SET (_fakedir "${PROJECT_SOURCE_DIR}/${PRIV_PATH}")
      IF (NOT IS_DIRECTORY "${_fakedir}")
        MESSAGE (STATUS "Creating directory ${_fakedir} with empty go.mod")
        FILE (MAKE_DIRECTORY "${_fakedir}")
      ENDIF ()
      SET (_fakegomod "${_fakedir}/go.mod")
      IF (NOT EXISTS "${_fakegomod}")
        FILE (TOUCH "${_fakedir}/go.mod")
      ENDIF ()
    ENDFOREACH ()
  ENDIF ()

  # End-cmake-hook which will write out all the go-version report information
  # collected by GET_GOROOT().
  FUNCTION (WRITE_GO_VERSIONS_REPORT)
    MESSAGE (STATUS "Producing Go version usage report")
    SET (_reportfile "${CMAKE_BINARY_DIR}/tlm/couchbase-server-${PRODUCT_VERSION}-go-versions.yaml")
    FILE (WRITE "${_reportfile}"
      "product: couchbase-server\n"
      "version: ${PRODUCT_VERSION}\n"
      "go-versions:\n"
    )
    GET_PROPERTY (_govers GLOBAL PROPERTY CB_GO_VERSIONS)
    FOREACH (_gover ${_govers})
      FILE (APPEND "${_reportfile}" "  - ${_gover}:\n")
      GET_PROPERTY (_goverusages GLOBAL PROPERTY CB_GO_VERSION_${_gover})
      FOREACH (_goverusage ${_goverusages})
        # Each entry here is a comma-separated list of four components. Turn
        # it into a CMake ;-separated list.
        STRING (REPLACE "," ";" _goverdetails "${_goverusage}")
        LIST (GET _goverdetails 0 _target)
        LIST (GET _goverdetails 1 _repodir)
        LIST (GET _goverdetails 2 _requestversion)
        LIST (GET _goverdetails 3 _usage)
        LIST (GET _goverdetails 4 _unshipped)
        IF (_unshipped)
          SET (_unshipped "true")
        ELSE ()
          SET (_unshipped "false")
        ENDIF ()
        FILE (APPEND "${_reportfile}"
          "    - target: ${_target}\n"
          "      repodir: ${_repodir}\n"
          "      requestversion: ${_requestversion}\n"
          "      usage: ${_usage}\n"
          "      unshipped: ${_unshipped}\n"
        )
      ENDFOREACH ()
    ENDFOREACH ()
  ENDFUNCTION (WRITE_GO_VERSIONS_REPORT)
  SET_PROPERTY (GLOBAL APPEND PROPERTY CB_CMAKE_END_HOOKS WRITE_GO_VERSIONS_REPORT)

  # This macro is called by GoModBuild() / GoYacc() / etc. to find the
  # appropriate Go compiler to use. This is also responsible for
  # creating the go-versions.csv artifact.
  # Parameters:
  #   VERSION - version of Go to use; may be eg. SUPPORTED_NEWER
  #   var - variable to set to the full path of GOROOT
  #   ver - variable to set to the final used Go version
  #   TARGET - name of target this root is being used for
  #   USAGE - usage of TARGET
  #   UNSHIPPED - true if TARGET is not a shipped deliverable
  MACRO (GET_GOROOT VERSION var ver TARGET USAGE UNSHIPPED)
    SET (_request_version ${VERSION})

    # If one of the constant Go versions is specified, read in the
    # corresponding Go major version from the golang repo
    IF ("${VERSION}" STREQUAL "SUPPORTED_OLDER" OR
        "${VERSION}" STREQUAL "SUPPORTED_NEWER")
      FILE (STRINGS "${CMAKE_SOURCE_DIR}/golang/versions/${VERSION}.txt"
            _request_version LIMIT_COUNT 1)
    ENDIF ()

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

    # If one of the constant Go versions is specified, read in the
    # corresponding Go major version from the golang repo
    IF ("${VERSION}" STREQUAL "SUPPORTED_OLDER" OR
        "${VERSION}" STREQUAL "SUPPORTED_NEWER")
      FILE (STRINGS "${CMAKE_SOURCE_DIR}/golang/versions/${VERSION}.txt"
            _request_version LIMIT_COUNT 1)
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
        MESSAGE (FATAL_ERROR "Go version ${_request_version} no longer supported - please upgrade!")
      ENDIF ()
    ELSE ()
      FILE (STRINGS "${GOVER_FILE}" _ver_final LIMIT_COUNT 1)
    ENDIF ()

    GET_GO_VERSION ("${_ver_final}" ${var})
    SET (${ver} ${_ver_final})
    SAVE_GO_TARGET (${_ver_final} ${_request_version} ${TARGET} ${USAGE} ${UNSHIPPED})
  ENDMACRO (GET_GOROOT)

  # Save a Go version usage, keyed by final Go version, as well as updating the
  # list of used Go versions.
  # Parameters:
  #   GOVER - fully-qualified Go version used to build the target
  #   REQUEST_GOVER - the initially-requested Go version, eg. SUPPORTED_NEWER
  #   TARGET - build target name
  #   USAGE - description of how the target is used in the build
  #   UNSHIPPED - true if TARGET is not a shipped deliverable
  MACRO (SAVE_GO_TARGET GOVER REQUEST_GOVER TARGET USAGE UNSHIPPED)
    FILE (RELATIVE_PATH _repodir "${CMAKE_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}")
    SET_PROPERTY (GLOBAL APPEND PROPERTY "CB_GO_VERSION_${GOVER}"
        "${TARGET},${_repodir},${REQUEST_GOVER},${USAGE},${UNSHIPPED}")
    GET_PROPERTY (_go_versions GLOBAL PROPERTY CB_GO_VERSIONS)
    LIST (APPEND _go_versions "${GOVER}")
    LIST (REMOVE_DUPLICATES _go_versions)
    LIST (SORT _go_versions COMPARE NATURAL)
    SET_PROPERTY (GLOBAL PROPERTY CB_GO_VERSIONS "${_go_versions}")
  ENDMACRO (SAVE_GO_TARGET)

  # Master target for "all go binaries"
  ADD_CUSTOM_TARGET(all-go)

  # Set up clean targets.
  SET (GO_BINARY_DIR "${CMAKE_BINARY_DIR}/gopkg")
  ADD_CUSTOM_TARGET (go_realclean
    COMMAND "${CMAKE_COMMAND}" -E remove_directory "${GO_BINARY_DIR}")
  ADD_DEPENDENCIES (realclean go_realclean)

  # Go build/install already performs it's own parallelism internally, so
  # we don't also want to have the CMake generator attempt to parallelise (i.e.
  # run multiple `go build/install` targets in parallel).
  # If we do (particulary for machines which have large numbers of CPUs but
  # perhaps not as large RAM) then we can end up exhausing the RAM of the
  # machine.
  # Define a CMake JOB_POOL which has concurrency 1, which is used by the
  # 'go build' custom targets below.
  # Note: At time of writing this is only supported by the Ninja generators,
  # is it ignored by other generators.
  SET_PROPERTY (GLOBAL APPEND PROPERTY JOB_POOLS golang_build_pool=1)

  # Top-level target which depends on all individual -tidy targets.
  ADD_CUSTOM_TARGET (go-mod-tidy)

  # Top-level target which runs go-mod-tidy repeatedly until no new
  # module changes are detected. This is necessary due to our use of
  # "replace" directives in go.mod files and circular dependencies.
  ADD_CUSTOM_TARGET (go-mod-tidy-all
    COMMAND "${CMAKE_COMMAND}"
      -D "REPO_SYNC_DIR=${PROJECT_SOURCE_DIR}"
      -P "${TLM_MODULES_DIR}/go-modtidyall.cmake"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Ensuring all go.mod files are tidied"
    VERBATIM)

  # Adds a target named TARGET which (always) calls "go build PACKAGE".
  # This delegates incremental-build responsibilities to the go
  # compiler, which is generally what you want. This target presumes
  # that the package in question is using Go modules to declare itself
  # and its dependencies. One consequence of this is that there must be
  # go.mod and go.sum files in the source directory that calls
  # GoModBuild() or some parent directory.
  #
  # Required arguments:
  #
  # TARGET - name of CMake target to create
  #
  # PACKAGE - A single Go package to build. This should produce a single
  # executable as output.
  #
  # GOVERSION - the version of the Go compiler required for this target.
  # See file header comment.
  #
  # Optional arguments:
  #
  # UNSHIPPED - for targets that are NOT part of the Server deliverable
  #
  # GCFLAGS - flags that will be passed (via -gcflags) to all compile
  # steps; should be a single string value, with spaces if necessary
  #
  # GOTAGS - tags that will be passed (viga -tags) to all compile steps;
  # should be a single string value, with spaces as necessary
  #
  # LDFLAGS - flags that will be passed (via -ldflags) to all compile
  # steps; should be a single string value, with spaces if necessary
  #
  # NOCONSOLE - for targets that should not launch a console at runtime
  # (on Windows - silently ignored on other platforms)
  #
  # DEPENDS - list of other CMake targets on which TARGET will depend.
  # These must be targets, representing either static or shared
  # libraries. They may be IMPORTED targets for eg. cbdeps, but may not
  # be specific library filenames.
  #
  # GEN_DEPENDS - DEPRECATED; will be removed
  #
  # INSTALL_PATH - if specified, a CMake INSTALL() directive will be
  # created to install the output into the named path. If this is a
  # relative path, it will be relative to CMAKE_INSTALL_PREFIX.
  #
  # OUTPUT - name of the produced executable. Default value is the
  # basename of PACKAGE, per the go compiler. On Windows, ".exe" will be
  # appended.
  #
  # CGO_INCLUDE_DIRS - path(s) to directories to search for C include
  # files
  #
  # CGO_LIBRARY_DIRS - path(s) to libraries to search for C link
  # libraries
  #
  MACRO (GoModBuild)

    PARSE_ARGUMENTS (Go "DEPENDS;GEN_DEPENDS;CGO_INCLUDE_DIRS;CGO_LIBRARY_DIRS"
      "TARGET;PACKAGE;OUTPUT;INSTALL_PATH;GOVERSION;GCFLAGS;GOTAGS;GOBUILDMODE;LDFLAGS"
      "NOCONSOLE;UNSHIPPED" ${ARGN})

    IF (NOT Go_TARGET)
      MESSAGE (FATAL_ERROR "TARGET is required!")
    ENDIF ()
    IF (NOT Go_PACKAGE)
      MESSAGE (FATAL_ERROR "PACKAGE is required!")
    ENDIF ()
    IF (NOT Go_GOVERSION)
      MESSAGE (FATAL_ERROR "GOVERSION is required!")
    ENDIF ()
    IF (NOT Go_GOBUILDMODE)
      SET(Go_GOBUILDMODE "default")
    ENDIF ()

    # Extract the binary name from the package, and tweak for Windows.
    IF (Go_OUTPUT)
      SET (_exename "${Go_OUTPUT}")
    ELSE ()
      GET_FILENAME_COMPONENT (_exename "${Go_PACKAGE}" NAME)
    ENDIF ()
    IF (WIN32)
      SET (_exename "${_exename}.exe")
    ENDIF ()
    SET (_exe "${CMAKE_CURRENT_BINARY_DIR}/${_exename}")

    # Concatenate NOCONSOLE with LDFLAGS
    IF (WIN32 AND ${Go_NOCONSOLE})
      SET (_ldflags "-H windowsgui ${Go_LDFLAGS}")
    ELSE ()
      SET (_ldflags "${Go_LDFLAGS}")
    ENDIF ()

    # DWARF header compression
    if (NOT CB_DWARF_HEADER_COMPRESSION)
      SET (_ldflags "${_ldflags} -compressdwarf=false")
    endif ()

    # Ensure GNU build-id is present
    if (UNIX AND NOT APPLE)
      SET (_ldflags "${_ldflags} -B gobuildid")
    endif ()

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
    GET_GOROOT ("${Go_GOVERSION}" _goroot _gover ${Go_TARGET} modules-build ${Go_UNSHIPPED})
    SET (_goexe "${_goroot}/bin/go")

    # Path to go binary dir for this target
    SET (_gobindir "${GO_BINARY_DIR}/go-${_gover}")

    # "Modern CMake" finally lets us define custom targets that
    # more-or-less act like real build targets, including having
    # link-library dependencies. These are called INTERFACE targets. You
    # are required to specify a "source" file to unlock this facility.
    # We use ${_exe} as a "source" file, which in turn sets up the
    # dependencies on the custom_command below which does all the real
    # compilation work. Frustratingly, only ADD_LIBRARY() has been
    # granted these new powers, so we use that, even though we're
    # creating an executable. This still doesn't allow us to use
    # INSTALL(TARGETS ...) either. Honestly it doesn't provide much
    # value over just using ADD_CUSTOM_TARGET() so far, but it does at
    # least allow us to use the INTERFACE_INCLUDE_DIRECTORIES target
    # property below to pass the right set of include paths to
    # go-modbuild.cmake.
    SET (_stub_tgt "${Go_TARGET}-cgo-stub")
    ADD_LIBRARY ("${_stub_tgt}" INTERFACE EXCLUDE_FROM_ALL)
    TARGET_LINK_LIBRARIES ("${_stub_tgt}" INTERFACE ${Go_DEPENDS})

    # More frustratingly, these INTERFACE targets don't seem to allow
    # direct access to the transitive set of library dependencies. We
    # could dig through INTERFACE_LINK_LIBRARIES recursively, except
    # that any value in any such list could be a $<> generator
    # expression which by definition we can't evaluate here at configure
    # time. After putting considerable time into this, I've come to the
    # conclusion that it's not possible in the most general case to form
    # the list of "all libraries that this target depends on" using only
    # CMake, even though CMake clearly has this knowledge. So, at least
    # for now, we have a requirement that the DEPENDS argument to
    # GoModBuild() must comprehensively list any targets (and only
    # targets!) required for building this Go target. With that
    # requirement, it is fairly straightforward to can compute the set
    # of -L directories for those direct library dependencies.
    SET (_depdirs ${Go_CGO_LIBRARY_DIRS})
    FOREACH (_dep ${Go_DEPENDS})
      IF (NOT TARGET ${_dep})
        CONTINUE ()
      ENDIF ()
      GET_TARGET_PROPERTY(_deptype ${_dep} TYPE)
      IF (_deptype MATCHES ".*_LIBRARY$")
        LIST (APPEND _depdirs "$<TARGET_FILE_DIR:${_dep}>")
      ENDIF ()
    ENDFOREACH ()

    # Go mod build command. It would be more clean if this was an
    # ADD_CUSTOM_COMMAND(), and the earlier INTERFACE library was named
    # ${Go_TARGET} rather than ${Go_TARGET}-cgo-stub. That actually
    # works with Makefile generators. However, it fails with Ninja,
    # because Ninja needs to create a rule both for the INTERFACE target
    # and for the output of the custom command, and there's no simple
    # and clear way to avoid those rules having the same name which
    # makes Ninja choke.
    ADD_CUSTOM_TARGET (
      ${Go_TARGET} ALL
      COMMAND "${CMAKE_COMMAND}"
        -D "GOEXE=${_goexe}"
        -D "GOVERSION=${_gover}"
        -D "GO_BINARY_DIR=${_gobindir}"
        -D "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
        -D "CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
        -D "REPOSYNC=${TLM_MODULES_DIR}/../../.."
        -D "CB_PRODUCTION_BUILD=${CB_PRODUCTION_BUILD}"
        -D "CGO_CFLAGS=$<TARGET_PROPERTY:${Go_TARGET},COMPILE_OPTIONS>"
        -D "CGO_LDFLAGS=$<TARGET_PROPERTY:${Go_TARGET},LINK_OPTIONS>"
        -D "GCFLAGS=${Go_GCFLAGS}"
        -D "GOTAGS=${Go_GOTAGS}"
        -D "GOBUILDMODE=${Go_GOBUILDMODE}"
        -D "LDFLAGS=${_ldflags}"
        -D "PACKAGE=${Go_PACKAGE}"
        -D "OUTPUT=${_exe}"
        -D "CGO_INCLUDE_DIRS=${Go_CGO_INCLUDE_DIRS};$<JOIN:$<TARGET_PROPERTY:${_stub_tgt},INTERFACE_INCLUDE_DIRECTORIES>,;>"
        -D "CGO_LIBRARY_DIRS=${_depdirs}"
        -D "CB_GO_CODE_COVERAGE=${CB_GO_CODE_COVERAGE}"
        -D "CB_GO_RACE_DETECTOR=${CB_GO_RACE_DETECTOR}"
        -D "CB_ADDRESSSANITIZER=${CB_ADDRESSSANITIZER}"
        -D "CB_UNDEFINEDSANITIZER=${CB_UNDEFINEDSANITIZER}"
        -D "CB_THREADSANITIZER=${CB_THREADSANITIZER}"
        -D "CB_GO_UNSHIPPED=${Go_UNSHIPPED}"
        -P "${TLM_MODULES_DIR}/go-modbuild.cmake"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
      COMMENT "Building Go Modules target ${Go_TARGET} using Go ${_gover}"
      JOB_POOL golang_build_pool
      VERBATIM)
    SET_PROPERTY (TARGET ${Go_TARGET} PROPERTY GO_BINARY "${_exe}")
    IF (Go_GEN_DEPENDS)
      ADD_DEPENDENCIES (${Go_TARGET} ${Go_GEN_DEPENDS})
    ENDIF ()
    IF (Go_DEPENDS)
      ADD_DEPENDENCIES (${Go_TARGET} ${Go_DEPENDS})
    ENDIF ()
    ADD_DEPENDENCIES (all-go ${Go_TARGET})
    MESSAGE (STATUS "Added Go Modules build target '${Go_TARGET}' using Go ${_gover}")

    # go-modbuild.cmake will produce the output executable in the
    # current binary dir. Install it from there if requested.
    IF (Go_INSTALL_PATH)
      INSTALL (PROGRAMS "${_exe}" DESTINATION "${Go_INSTALL_PATH}")
    ENDIF ()

    # Debugging targets
    IF (CB_DEBUG_GO_TARGETS)
      FILE(GENERATE OUTPUT /tmp/whoa-${Go_TARGET}.txt CONTENT "${_stub_tgt}: $<LIST:TRANSFORM,$<TARGET_PROPERTY:${_stub_tgt},INTERFACE_LINK_LIBRARIES>,REPLACE,cb,hello>
      ")
      MESSAGE (STATUS "Dep target info for GoModBuild(${Go_TARGET})")
      MESSAGE (STATUS "CGO_CFLAGS: ${Go_CGO_CFLAGS}")
      FOREACH (_dep ${Go_TARGET} ${Go_DEPENDS} ${Go_GEN_DEPENDS})
        PRINT_TARGET_PROPERTIES (${_dep})
      ENDFOREACH ()
      MESSAGE (STATUS "End dep target info for GoModBuild(${Go_TARGET})")
    ENDIF ()

  ENDMACRO (GoModBuild)

  # Creates the target for tidying a Go module. All projects with a
  # `go.mod` file should call this, even if they don't have any built
  # artifacts.
  #
  # Optional arguments:
  #
  # DEPENDS - any targest that must be called before `go mod tidy`, such
  # as code generation.
  #
  # DIRECTORY - the directory containing the `go.mod` file. Defaults to
  # the current source dir.
  #
  # MODNAME - short name of the module. If not specified, the name of
  # the directory will be used. The generated target will be named
  # MODNAME-tidy.
  #
  # GOVERSION - the version of the Go compiler required for this target.
  # Defaults to SUPPORTED_NEWER.
  MACRO (GoModTidySetup)
    PARSE_ARGUMENTS (Tidy "DEPENDS;DIRECTORY;MODNAME;GOVERSION" "" "" ${ARGN})

    IF (NOT Tidy_DIRECTORY)
      SET (Tidy_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
    ENDIF ()
    IF (NOT Tidy_MODNAME)
      GET_FILENAME_COMPONENT (Tidy_MODNAME "${Tidy_DIRECTORY}" NAME)
    ENDIF ()
    IF (NOT Tidy_GOVERSION)
      SET (Tidy_GOVERSION SUPPORTED_NEWER)
    ENDIF ()

    SET (_tidy_target "${Tidy_MODNAME}-tidy")
    GET_GOROOT ("${Tidy_GOVERSION}" _goroot _gover ${_tidy_target} tidy 1)
    SET (_goexe "${_goroot}/bin/go")

    ADD_CUSTOM_TARGET ("${_tidy_target}"
      COMMAND "${CMAKE_COMMAND}"
        -D "GOEXE=${_goexe}"
        -D "GO_BINARY_DIR=${GO_BINARY_DIR}/go-${_gover}"
        -D "CB_PRODUCTION_BUILD=${CB_PRODUCTION_BUILD}"
        -P "${TLM_MODULES_DIR}/go-modtidy.cmake"
      WORKING_DIRECTORY "${Tidy_DIRECTORY}"
      COMMENT "Tidying go.mod for ${Tidy_MODNAME} using Go ${_gover}"
      VERBATIM)
    MESSAGE (STATUS "Added Go mod tidy target ${_tidy_target}")
    ADD_DEPENDENCIES (go-mod-tidy "${_tidy_target}")
    IF (Tidy_DEPENDS)
      ADD_DEPENDENCIES ("${_tidy_target}" ${Tidy_DEPENDS})
    ENDIF ()

    # Save this directory in global list
    SET_PROPERTY (GLOBAL APPEND PROPERTY CB_GO_MOD_TIDY_DIRS "${Tidy_DIRECTORY}")

  ENDMACRO (GoModTidySetup)

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
  GET_GOROOT ("${Go_GOVERSION}" _goroot _gover ${Go_TARGET} test 1)

  add_test(NAME "${Go_TARGET}"
             COMMAND "${CMAKE_COMMAND}"
             -D "GOROOT=${_goroot}"
             -D "GOVERSION=${_gover}"
             -D "GO_BINARY_DIR=${GO_BINARY_DIR}/go-${_gover}"
             -D "CMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
             -D "CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
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
  MACRO (GoYacc)

    PARSE_ARGUMENTS (goyacc "DEPENDS" "TARGET;YFILE" "" ${ARGN})

    # Only build this target if somebody uses this macro
    SET (_goyacc_exe "${CMAKE_BINARY_DIR}/tlm/goyacc")
    IF (NOT TARGET goyacc)
      GET_GOROOT (SUPPORTED_NEWER _goroot _gover goyacc goyacc-build 1)
      SET (_goexe "${_goroot}/bin/go")
      IF (WIN32)
        SET (_goexe "${_goexe}.exe")
      ENDIF ()
      ADD_CUSTOM_COMMAND(OUTPUT "${_goyacc_exe}"
        COMMAND "${CMAKE_COMMAND}"
        -D "GOYACC_EXE=${_goyacc_exe}"
        -D "GOROOT=${_goroot}"
        -P "${TLM_MODULES_DIR}/go-buildyacc.cmake"
        COMMENT "Building goyacc using Go ${_gover}"
        JOB_POOL golang_build_pool
        VERBATIM
      )
      ADD_CUSTOM_TARGET(goyacc ALL DEPENDS "${_goyacc_exe}")
    ENDIF ()

    IF (NOT goyacc_TARGET)
      MESSAGE (FATAL_ERROR "TARGET is required!")
    ENDIF (NOT goyacc_TARGET)
    IF (NOT goyacc_YFILE)
      MESSAGE (FATAL_ERROR "YFILE is required!")
    ENDIF (NOT goyacc_YFILE)

    GET_FILENAME_COMPONENT (_ypath "${goyacc_YFILE}" PATH)
    GET_FILENAME_COMPONENT (_yfile "${goyacc_YFILE}" NAME)

    SET(goyacc_OUTPUT "${_ypath}/y.go")
    ADD_CUSTOM_COMMAND(OUTPUT "${goyacc_OUTPUT}"
                       COMMAND "${CMAKE_COMMAND}"
                       -D "GOROOT=${_goroot}"
                       -D "GOYACC_EXECUTABLE=${_goyacc_exe}"
                       -D "YFILE=${_yfile}"
                       -P "${TLM_MODULES_DIR}/go-yacc.cmake"
                       DEPENDS ${goyacc_YFILE} goyacc
                       WORKING_DIRECTORY "${_ypath}"
                       COMMENT "Build Go yacc target ${goyacc_TARGET}"
                       VERBATIM)
    ADD_CUSTOM_TARGET ("${goyacc_TARGET}"
                       DEPENDS "${goyacc_OUTPUT}")
    MESSAGE (STATUS "Added Go yacc target '${goyacc_TARGET}' using Go ${_gover}")

    IF (Go_DEPENDS)
      ADD_DEPENDENCIES (${goyacc_TARGET} ${goyacc_DEPENDS})
    ENDIF (Go_DEPENDS)

  ENDMACRO (GoYacc)

  # Create 'tidy' rules for all library modules. Skip those that don't
  # exist (could be private repositories).
  FOREACH (_modpath ${GO_LIBRARY_MODULE_PATHS})
    IF (IS_DIRECTORY "${PROJECT_SOURCE_DIR}/${_modpath}")
      GoModTidySetup (DIRECTORY "${PROJECT_SOURCE_DIR}/${_modpath}")
    ENDIF ()
  ENDFOREACH ()

  # QQQ Also create 'tidy' rules for projects that haven't submitted
  # their own changes yet.
  FOREACH (_modpath ${GO_LIBRARY_MODULE_PATHS_SOON})
    IF (IS_DIRECTORY "${PROJECT_SOURCE_DIR}/${_modpath}")
      GET_FILENAME_COMPONENT (_modname "${PROJECT_SOURCE_DIR}/${_modpath}" NAME)
      GoModTidySetup (DIRECTORY "${PROJECT_SOURCE_DIR}/${_modpath}" MODNAME temp-${_modname})
    ENDIF ()
  ENDFOREACH ()

  SET (FindCouchbaseGo_INCLUDED 1)

ENDIF (NOT FindCouchbaseGo_INCLUDED)
