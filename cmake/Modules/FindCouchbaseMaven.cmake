# This module provides simple facilities for building a Java Maven project.

# Prevent double-definition if two projects use this script
IF (NOT FindCouchbaseMaven_INCLUDED)

  INCLUDE (ParseArguments)

  FIND_PROGRAM (MAVEN_EXECUTABLE mvn)

  IF (MAVEN_EXECUTABLE)
    MESSAGE (STATUS "Found Maven executable: ${MAVEN_EXECUTABLE}")
    SET (MAVEN_FOUND True CACHE BOOL "Whether Maven has been found")

    SET (CB_INVOKE_MAVEN False CACHE BOOL "Whether to add Maven targets to ALL")

    # Create a target to build a Maven project from a specified directory.
    # Since Maven is slow and painful and in particular has terrible
    # incremental build ability, this target will not be added to ALL
    # unless the build parameter CB_INVOKE_MAVEN is True.
    #
    # Since it's not in ALL, using INSTALL() is probably a bad idea. As a
    # workaround, this macro allows you to specify a single directory of
    # artifacts from the build, which will be copied into the installation
    # directory as part of the target itself.
    #
    # This macro also adds a "-clean" target.
    #
    # Required arguments:
    #   TARGET - name of CMake target to create
    #
    # Optional arguments:
    #   PATH - directory containing Maven project (defaults to current src dir)
    #   ARTIFACTS - path (relative to PATH) to directory containing
    #               artifacts to install
    #   DESTINATION - path (relative to CMAKE_INSTALL_DIR) to install ARTIFACTS
    #                 (must be specified if ARTIFACTS is specified, and must
    #                 contain a slash to prevent eg. blowing away "lib")

    MACRO (MAVEN_PROJECT)
      PARSE_ARGUMENTS (Mvn "" "TARGET;PATH;ARTIFACTS;DESTINATION" "" ${ARGN})
      IF ("${Mvn_PATH}" STREQUAL "")
        SET (Mvn_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
      ENDIF ()

      MESSAGE (STATUS "Adding Maven project target '${Mvn_TARGET}'")
      IF (NOT "${Mvn_ARTIFACTS}" STREQUAL "")
        STRING (FIND "${Mvn_DESTINATION}" "/" _pos)
        IF (_pos LESS 0)
          MESSAGE (FATAL_ERROR "Must specify DESTINATION (containing a '/') if ARTIFACTS specified")
        ENDIF ()
        ADD_CUSTOM_TARGET ("${Mvn_TARGET}-install"
          COMMAND "${CMAKE_COMMAND}" -E remove_directory
            "${CMAKE_INSTALL_PREFIX}/${Mvn_DESTINATION}"
          COMMAND "${CMAKE_COMMAND}" -E copy_directory
            "${Mvn_PATH}/${Mvn_ARTIFACTS}"
            "${CMAKE_INSTALL_PREFIX}/${Mvn_DESTINATION}"
          COMMENT "Installing artifacts for Maven project ${Mvn_TARGET}"
          VERBATIM)
      ENDIF ()
      ADD_CUSTOM_TARGET ("${Mvn_TARGET}-build"
        COMMAND "${MAVEN_EXECUTABLE}" package -DskipTests
        WORKING_DIRECTORY "${Mvn_PATH}"
        COMMENT "Building Maven project ${Mvn_TARGET}"
        VERBATIM)
      SET (_all "")
      IF (CB_INVOKE_MAVEN)
        SET (_all "ALL")
      ENDIF ()
      ADD_CUSTOM_TARGET ("${Mvn_TARGET}" ${_all})
      IF (TARGET "${Mvn_TARGET}-install")
        ADD_DEPENDENCIES ("${Mvn_TARGET}-install" "${Mvn_TARGET}-build")
        ADD_DEPENDENCIES ("${Mvn_TARGET}" "${Mvn_TARGET}-install")
      ELSE ()
        ADD_DEPENDENCIES ("${Mvn_TARGET}" "${Mvn_TARGET}-build")
      ENDIF ()

      ADD_CUSTOM_TARGET ("${Mvn_TARGET}-clean"
        COMMAND "${MAVEN_EXECUTABLE}" clean
        WORKING_DIRECTORY "${Mvn_PATH}"
        VERBATIM)
      IF (TARGET realclean)
        ADD_DEPENDENCIES (realclean "${Mvn_TARGET}-clean")
      ENDIF ()

    ENDMACRO (MAVEN_PROJECT)

  ELSE (MAVEN_EXECUTABLE)
    MESSAGE (STATUS "Maven not found - Java subprojects will be skipped")
    SET (MAVEN_FOUND False CACHE BOOL "Whether Maven has been found")
    MACRO (MAVEN_PROJECT)
      PARSE_ARGUMENTS (Mvn "" "TARGET;PATH;ARTIFACTS;DESTINATION" "" ${ARGN})
      MESSAGE (STATUS "NOTE: Not doing anything for Maven target '${Mvn_TARGET}'")
    ENDMACRO (MAVEN_PROJECT)
  ENDIF (MAVEN_EXECUTABLE)

  SET (FindCouchbaseMaven_INCLUDED 1)
ENDIF (NOT FindCouchbaseMaven_INCLUDED)
