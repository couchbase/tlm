# This module provides simple facilities for building a Java Maven project.

# Prevent double-definition if two projects use this script
IF (NOT FindCouchbaseMaven_INCLUDED)

  INCLUDE (ParseArguments)

  SET (_maven_exploded "${CMAKE_BINARY_DIR}/tlm/deps/maven.exploded")
  IF (WIN32)
    SET (_mvn_program mvn.cmd)
  ELSE (WIN32)
    SET (_mvn_program mvn)
  ENDIF (WIN32)
  FIND_PROGRAM (MAVEN_EXECUTABLE ${_mvn_program}
                HINTS
                    "${_maven_exploded}/bin"
                PATHS
                    ~/Library/Frameworks
                    /Library/Frameworks
                    /opt/local
                    /opt/csw
                    /opt/maven
                    /opt)

  # Keep these arguments separated here, to prevent the with-Maven and
  # without-Maven versions of MAVEN_PROJECT() from falling out of sync
  SET (_multi_args "OPTS")
  SET (_single_args "TARGET;GOAL;PATH;ARTIFACTS;DESTINATION")
  SET (_option_args "")

  IF (MAVEN_EXECUTABLE)
    MESSAGE (STATUS "Found Maven executable: ${MAVEN_EXECUTABLE}")
    SET (MAVEN_FOUND True CACHE BOOL "Whether Maven has been found")

    SET (CB_INVOKE_MAVEN True CACHE BOOL "Whether to add Maven targets to ALL")

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
    #   GOAL - the Maven goal to invoke (defaults to 'package')
    #   PATH - directory containing Maven project (defaults to current src dir)
    #   ARTIFACTS - path (relative to PATH) to directory containing
    #               artifacts to install
    #   DESTINATION - path (relative to CMAKE_INSTALL_DIR) to install ARTIFACTS
    #                 (must be specified if ARTIFACTS is specified, and must
    #                 contain a slash to prevent eg. blowing away "lib")
    #   OPTS - additional command-line options to pass to 'mvn'. Defaults to
    #          -DskipTests (but if you provide a value here and want to still
    #          skip tests, you'll need to explicitly include -DskipTests)

    MACRO (MAVEN_PROJECT)
      PARSE_ARGUMENTS (Mvn "${_multi_args}" "${_single_args}" "${_option_args}" ${ARGN})
      IF ("${Mvn_PATH}" STREQUAL "")
        SET (Mvn_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
      ENDIF ()
      IF ("${Mvn_GOAL}" STREQUAL "")
        SET (Mvn_GOAL package)
      ENDIF ()
      IF ("${Mvn_OPTS}" STREQUAL "")
        SET (Mvn_OPTS -DskipTests)
      ENDIF ()

      INCLUDE (FindCouchbaseJava)

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
        COMMAND "${CMAKE_COMMAND}" -E env "JAVACMD=${Java_JAVA_EXECUTABLE}"
          "${MAVEN_EXECUTABLE}" "${Mvn_GOAL}" ${Mvn_OPTS}
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
        COMMAND "${CMAKE_COMMAND}" -E env "JAVACMD=${Java_JAVA_EXECUTABLE}"
          "${MAVEN_EXECUTABLE}" clean
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
      PARSE_ARGUMENTS (Mvn "${_multi_args}" "${_single_args}" "${_option_args}" ${ARGN})
      MESSAGE (STATUS "NOTE: Not doing anything for Maven target '${Mvn_TARGET}'")
    ENDMACRO (MAVEN_PROJECT)
  ENDIF (MAVEN_EXECUTABLE)

  SET (FindCouchbaseMaven_INCLUDED 1)
ENDIF (NOT FindCouchbaseMaven_INCLUDED)
