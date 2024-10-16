# Helper functions for installing dependencies of an executable. These
# functions are intended to be called via an `INSTALL(CODE)` directive,
# not at configuration time.
#
# These functions generally assume everything is to be installed into
# `bin` or `lib` directories.


# Install the runtime dependencies of an executable.
# Required arguments:
#
# binary - The path to the binary to install dependencies for.
# type - The type of the binary; must be EXECUTABLES or LIBRARIES.
#
# Any additional arguments will be treated as directories to search for
# dependencies at install time. This should generally only be used on
# Windows, where the runtime search paths are not embedded in the binary.
FUNCTION (InstallDependencies binary type)
  MESSAGE (STATUS "Installing ${binary} dependencies")
  # We exclude GCC libs that we've already copied to the right place in
  # the top-level CMakeLists.txt, as well as any libc-like libraries
  # that come from the OS itself. We also exclude deps found under
  # CMAKE_INSTALL_PREFIX; we prefer to install them from the binary
  # tree.
  FILE (
    GET_RUNTIME_DEPENDENCIES
      ${type} "${binary}"
    DIRECTORIES ${ARGN}
    PRE_EXCLUDE_REGEXES
      "^ld-linux.*"
      "^api-ms-win.*" "^ext-ms-win.*" "^ext-ms-onecore.*"
    POST_EXCLUDE_REGEXES
      "^/lib.*" "^/usr/lib.*" "^/opt/gcc.*" "${CMAKE_INSTALL_PREFIX}/.*"
    RESOLVED_DEPENDENCIES_VAR _deplibs
    UNRESOLVED_DEPENDENCIES_VAR _unresolvedeps
    CONFLICTING_DEPENDENCIES_PREFIX _conflicts
  )

  # Fail if we have any conflicting or unresolved dependencies.
  FOREACH (_con ${_conflicts_FILENAMES})
    message(
      WARNING "Dependency `${_con}` resolved to multiple locations: "
      "${_conflicts_${_con}}"
    )
  ENDFOREACH()
  IF (_unresolvedeps)
    message(WARNING "Unresolved dependencies: ${_unresolvedeps}")
  ENDIF ()
  IF (_conflicts_FILENAMES OR _unresolvedeps)
    message(
      FATAL_ERROR "Failed to resolve dependencies for ${binary} "
      "(see above messages)"
    )
  ENDIF ()

  # All dependencies are libraries, so they all go to the same dir.
  IF (WIN32)
    SET (_libdir bin)
  ELSE ()
    SET (_libdir lib)
  ENDIF ()
  SET (_installlibdir "${CMAKE_INSTALL_PREFIX}/${_libdir}")

  # Copy the dependencies to the install lib directory.
  FOREACH (_dep ${_deplibs})
    FILE (
      INSTALL "${_dep}"
      DESTINATION "${_installlibdir}"
      FOLLOW_SYMLINK_CHAIN USE_SOURCE_PERMISSIONS
    )
    CMAKE_PATH (GET _dep FILENAME _depname)
    SET (_installdep "${_installlibdir}/${_depname}")

    # Optionally strip the installed dependency.
    IF (CMAKE_INSTALL_DO_STRIP)
      MESSAGE (STATUS "Stripping: ${CMAKE_STRIP} ${_installdep}")
      EXECUTE_PROCESS (
        COMMAND "${CMAKE_STRIP}" --strip-all "${_installdep}"
      )
    ENDIF ()
  ENDFOREACH ()
ENDFUNCTION (InstallDependencies)
