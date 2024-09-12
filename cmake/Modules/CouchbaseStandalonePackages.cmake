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

  # This one is just for the Developer Tools
  INSTALL (
    FILES "${CMAKE_SOURCE_DIR}/product-texts/capella/tools/README.txt"
    DESTINATION ${dev_tools_INSTALL_PREFIX}
    EXCLUDE_FROM_ALL COMPONENT dev_tools
  )

  # This one is for all tools
  FOREACH (pkg ${CB_EXTRA_PACKAGES})
    INSTALL (
      FILES "${CMAKE_SOURCE_DIR}/product-texts/couchbase-server/license/ee-license.txt"
      RENAME "LICENSE.txt"
      DESTINATION ${${pkg}_INSTALL_PREFIX}
      EXCLUDE_FROM_ALL COMPONENT ${pkg}
    )
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
  # TARGETS - names of existing executable TARGETs. Each target must be
  # either a standard ADD_EXECUTABLE() target or one created by
  # GoModBuild(). Additionally, the output executable of the target must
  # be installed to ${CMAKE_INSTALL_PREFIX}/bin.
  MACRO (AddToStandalonePackage)

    PARSE_ARGUMENTS (Pkg "PACKAGES;TARGETS" "" "" ${ARGN})

    IF (NOT Pkg_PACKAGES)
      MESSAGE (FATAL_ERROR "PACKAGES is required!")
    ENDIF ()
    IF (NOT Pkg_TARGETS)
      MESSAGE (FATAL_ERROR "TARGETS is required!")
    ENDIF ()

    FOREACH (target ${Pkg_TARGETS})
      # Full path to the original compiled program
      GET_TARGET_PROPERTY (_exe ${target} GO_BINARY)
      IF (_exe)
        SET (_gotarget TRUE)
        # Extract the filename
        CMAKE_PATH (GET _exe FILENAME _exename)
      ELSE ()
        # Not a GoModBuild() target; get it from the generated build system
        SET (_gotarget FALSE)
        SET (_exe "$<TARGET_FILE:${target}>")
        SET (_exename "$<TARGET_FILE_NAME:${target}>")
      ENDIF ()

      FOREACH (pkg ${Pkg_PACKAGES})
        # Install the binary itself
        IF (_gotarget)
          INSTALL (
            PROGRAMS ${_exe}
            DESTINATION "${${pkg}_INSTALL_PREFIX}/bin"
            EXCLUDE_FROM_ALL COMPONENT ${pkg}
          )
        ELSE ()
          INSTALL (
            TARGETS ${target}
            DESTINATION "${${pkg}_INSTALL_PREFIX}/bin"
            EXCLUDE_FROM_ALL COMPONENT ${pkg}
          )
        ENDIF ()

        # Create a code block to be used with INSTALL(CODE). We need to do
        # a bit of variable substitution into this block, so start with it
        # in a simple string.
        #
        # The install code looks up the runtime dependencies of the binary
        # that was installed into CMAKE_INSTALL_PREFIX (assumed to be
        # installed into bin/). Those dependencies will therefore be
        # discovered from CMAKE_INSTALL_PREFIX/lib, which is good, because
        # those are the versions that CMake has done wacky RPATH
        # manipulations to for us. We don't want to copy, eg.,
        # libmagma_shared.so from the build tree.
        #
        # We exclude GCC libs that we've already copied to the right place
        # in the top-level CMakeLists.txt, as well as any libc-like
        # libraries that come from the OS itself.
        SET (_code [[
          IF (CMAKE_INSTALL_DO_STRIP)
            MESSAGE (STATUS "Stripping: ${@@PKG@@_INSTALL_PREFIX}/bin/@@EXE_NAME@@")
            EXECUTE_PROCESS (
              COMMAND "${CMAKE_STRIP}" "${@@PKG@@_INSTALL_PREFIX}/bin/@@EXE_NAME@@"
            )
          ENDIF ()
          MESSAGE (STATUS "Adding @@EXE_NAME@@ dependencies to @@PKG@@ package")
          FILE (
            GET_RUNTIME_DEPENDENCIES
            EXECUTABLES "${CMAKE_INSTALL_PREFIX}/bin/@@EXE_NAME@@"
            PRE_EXCLUDE_REGEXES "^ld-linux.*"
            POST_EXCLUDE_REGEXES "^/lib.*" "^/usr/lib.*" "^/opt/gcc.*"
            RESOLVED_DEPENDENCIES_VAR _deplibs
            UNRESOLVED_DEPENDENCIES_VAR _unresolvedeps
          )
          IF (WIN32)
            SET (_libdir bin)
          ELSE ()
            SET (_libdir lib)
          ENDIF ()
          SET (_installlibdir "${@@PKG@@_INSTALL_PREFIX}/${_libdir}")
          FOREACH (_dep ${_deplibs})
            FILE (
              INSTALL "${_dep}"
              DESTINATION "${_installlibdir}"
              FOLLOW_SYMLINK_CHAIN USE_SOURCE_PERMISSIONS
            )
            CMAKE_PATH (GET _dep FILENAME _depname)
            SET (_installdep "${_installlibdir}/${_depname}")
            IF (CMAKE_INSTALL_DO_STRIP)
              MESSAGE (STATUS "Stripping: ${CMAKE_STRIP} ${_installdep}")
              EXECUTE_PROCESS (
                COMMAND "${CMAKE_STRIP}" --strip-all "${_installdep}"
              )
            ENDIF ()
          ENDFOREACH ()
        ]])

        STRING (REPLACE @@EXE_NAME@@ "${_exename}" _code "${_code}")
        STRING (REPLACE @@PKG@@ "${pkg}" _code "${_code}")
        INSTALL (CODE "${_code}" EXCLUDE_FROM_ALL COMPONENT ${pkg})

      ENDFOREACH (pkg)
    ENDFOREACH (target)
  ENDMACRO (AddToStandalonePackage)

  SET (CouchbaseExtraPackages_INCLUDED 1)
ENDIF (NOT CouchbaseExtraPackages_INCLUDED)
