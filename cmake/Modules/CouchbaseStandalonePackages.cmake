# Functions and configuration for "extra packages", which are additional
# release artifacts from a couchbase-server build that contain subsets
# of Server targets.
#
# Projects that need to add executable targets (ADD_EXECUTABLE() or
# GoModBuild()) should use the AddToStandalonePackage() macro defined
# here.
#
# Projects that need to add Python programs should use the
# ADD_TO_STANDALONE_PACKAGE argument to PyWrapper().
#
# Projects that need to add other content (docs, etc.) can use
# additional INSTALL() directives specifying the DESTINATION
# ${pkg}_INSTALL_PREFIX, eg. admin_tools_INSTALL_PREFIX.
#
# The set of known extra packages is defined here in CB_EXTRA_PACKAGES.

IF (NOT CouchbaseExtraPackages_INCLUDED)

  # The master list of available packages. These correspond to CMake
  # "components" with the same name.
  SET (CB_EXTRA_PACKAGES dev_tools admin_tools)

  # Targets for standalone packages, and the master
  # "standalone-packages" target.
  #
  # Note: These targets depend on the build being already complete, but
  # you can't do that literally in CMake. So it's important that these
  # targets only be invoked after running the full build, eg. by running
  # "make install".
  #
  # Since we can't have proper dependency tracking anyway, we just use
  # simple ADD_CUSTOM_TARGETs rather than the more proper
  # ADD_CUSTOM_COMMAND setup.
  _DETERMINE_BASIC_PLATFORM (_platform)
  SET (standalone_root "${PROJECT_BINARY_DIR}/standalone-packages")
  ADD_CUSTOM_TARGET(standalone-packages)
  FOREACH (pkg ${CB_EXTRA_PACKAGES})
    # Just to make the targets and output filenames a little prettier
    STRING (REPLACE _ - pkg_dash ${pkg})
    SET (pkg_dir "couchbase-server-${pkg_dash}-${PRODUCT_VERSION}")

    # Set this globally - some parts of the code need to reference it,
    # eg. to install doc files
    SET ("${pkg}_INSTALL_PREFIX" "${standalone_root}/${pkg_dir}" CACHE INTERNAL "")

    # Make sure INSTALL(CODE) blocks know about this prefix too, as well
    # as the strip command.
    INSTALL (
      CODE "SET (${pkg}_INSTALL_PREFIX \"${${pkg}_INSTALL_PREFIX}\")"
      EXCLUDE_FROM_ALL COMPONENT ${pkg}
    )
    INSTALL (
      CODE "SET (CMAKE_STRIP \"${CMAKE_STRIP}\")"
      EXCLUDE_FROM_ALL COMPONENT ${pkg}
    )

    # Package-specific README
    INSTALL (
      FILES "${CMAKE_SOURCE_DIR}/product-texts/couchbase-server/${pkg_dash}/README.txt"
      DESTINATION ${${pkg}_INSTALL_PREFIX}
      EXCLUDE_FROM_ALL COMPONENT ${pkg}
    )
    # General EE license for all packages
    INSTALL (
      FILES "${CMAKE_SOURCE_DIR}/product-texts/couchbase-server/license/ee-license.txt"
      RENAME "LICENSE.txt"
      DESTINATION ${${pkg}_INSTALL_PREFIX}
      EXCLUDE_FROM_ALL COMPONENT ${pkg}
    )

    STRING (CONCAT _archive_base
      "${CMAKE_BINARY_DIR}/${pkg_dir}"
      "-${_platform}"
      "_${CB_DOWNLOAD_DEPS_ARCH}"
    )
    ADD_CUSTOM_TARGET (${pkg_dash}-install
      COMMAND "${CMAKE_COMMAND}" --install . --component ${pkg} --strip
      WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
      COMMENT "Installing ${pkg} component"
    )
    IF (WIN32 OR APPLE)
      ADD_CUSTOM_TARGET (${pkg_dash}-package
        DEPENDS ${pkg_dash}-install
        COMMAND "${CMAKE_COMMAND}" -E
          tar cf "${_archive_base}.zip" --format=zip "${pkg_dir}"
        WORKING_DIRECTORY "${standalone_root}"
        COMMENT "Creating ${pkg} package at ${_archive_base}.zip"
      )
    ELSE (WIN32 OR APPLE)
      ADD_CUSTOM_TARGET (${pkg_dash}-package
        DEPENDS ${pkg_dash}-install
        COMMAND "${CMAKE_COMMAND}" -E
          tar czf "${_archive_base}.tar.gz" "${pkg_dir}"
        WORKING_DIRECTORY "${standalone_root}"
        COMMENT "Creating ${pkg} package at ${_archive_base}.tar.gz"
      )
    ENDIF (WIN32 OR APPLE)
    ADD_DEPENDENCIES(standalone-packages ${pkg_dash}-package)
  ENDFOREACH ()
  FOREACH (pkg ${CB_EXTRA_PACKAGES})
  ENDFOREACH ()

  INCLUDE (ParseArguments)
  INCLUDE (PlatformIntrospection)

  # Add an installed program and all its runtime dependencies to an
  # extra package.
  #
  # Required arguments:
  #
  # PACKAGES - list of extra packages to add this program to.
  #
  # EXES - list of binaries to add to the package. Assumed to be already
  # installed in ${CMAKE_INSTALL_PREFIX}/bin. (Omit the `.exe` extension
  # on Windows.)
  #
  # (Temporarily, TARGETS is a synonym for EXES)
  MACRO (AddToStandalonePackage)

    PARSE_ARGUMENTS (Pkg "PACKAGES;TARGETS;EXES" "" "" ${ARGN})

    # Use TARGETS if set - this should be removed
    IF (Pkg_TARGETS)
      SET (Pkg_EXES ${Pkg_TARGETS})
    ENDIF ()
    IF (NOT Pkg_PACKAGES)
      MESSAGE (FATAL_ERROR "PACKAGES is required!")
    ENDIF ()
    IF (NOT Pkg_EXES)
      MESSAGE (FATAL_ERROR "EXES is required!")
    ENDIF ()

    FOREACH (_exename ${Pkg_EXES})
      IF (WIN32)
        SET (_exename "${_exename}.exe")
      ENDIF ()
      SET (_exe "${CMAKE_INSTALL_PREFIX}/bin/${_exename}")

      FOREACH (pkg ${Pkg_PACKAGES})
        # Install the binary itself
        INSTALL (
          PROGRAMS ${_exe}
          DESTINATION "${${pkg}_INSTALL_PREFIX}/bin"
          EXCLUDE_FROM_ALL COMPONENT ${pkg}
        )

        # Create a code block to be used with INSTALL(CODE). We need to
        # do a bit of variable substitution into this block, so start
        # with it in a simple string.
        #
        # The install code first strips the already-installed binary,
        # since we want the standalone packages to be fully stripped. It
        # also strips any GCC RPATHs from the binary.
        #
        # It then calls cb_install_deps() to install the runtime
        # dependencies of this binary. It specifies the binary *in
        # CMAKE_INSTALL_PREFIX/bin*, because it wants to resolve all
        # built dependencies (such as libmagma_prefix.so) from
        # CMAKE_INSTALL_PREFIX/lib. We want to copy those dependencies
        # from CMAKE_INSTALL_PREFIX because CMake will have done all of
        # the RPATH-manipulation steps to those versions. This is why
        # the `standalone-packages` build targets can only be run
        # *after* the full normal `install` target is invoked.
        #
        # Note: the blank line after the [[ makes the code inserted into
        # `cmake_install.cmake` more readable.
        SET (_code [[

          IF (CMAKE_INSTALL_DO_STRIP)
            MESSAGE (STATUS "Stripping: ${@@PKG@@_INSTALL_PREFIX}/bin/@@EXE_NAME@@")
            EXECUTE_PROCESS (
              COMMAND "${CMAKE_STRIP}" "${@@PKG@@_INSTALL_PREFIX}/bin/@@EXE_NAME@@"
            )
          ENDIF ()
          cb_strip_gcc_rpath("${@@PKG@@_INSTALL_PREFIX}/bin/@@EXE_NAME@@")
          IF (WIN32)
            SET (_libdir bin)
          ELSE ()
            SET (_libdir lib)
          ENDIF ()
          cb_install_deps (
            "@@EXE@@"
            EXECUTABLES
            "${@@PKG@@_INSTALL_PREFIX}"
          )
        ]])

        STRING (REPLACE @@EXE@@ "${_exe}" _code "${_code}")
        STRING (REPLACE @@EXE_NAME@@ "${_exename}" _code "${_code}")
        STRING (REPLACE @@PKG@@ "${pkg}" _code "${_code}")
        cb_install_code (
          CODE "${_code}"
          COMPONENTS ${pkg}
        )

      ENDFOREACH (pkg)
    ENDFOREACH (_exename)
  ENDMACRO (AddToStandalonePackage)

  SET (CouchbaseExtraPackages_INCLUDED 1)
ENDIF (NOT CouchbaseExtraPackages_INCLUDED)
