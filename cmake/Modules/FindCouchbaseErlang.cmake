#find the erlang path
#
# This file is based upon http://code.google.com/p/erlcmake/ which
# is released under MPL 1.1. We've however made "significant" changes
# to make it work for our needs.
#
#
# This module defines
#  ERLANG_FOUND, if erl and erlc is available
#  ERL_EXECUTABLE, The name of name of the erlang runtime
#  ERLC_EXECUTABLE, The name of name of the erlang compiler
#  ERLSCRIPT_EXECUTABLE, The name of the escript interpreter
#  ERLANG_INCLUDE_PATH, The directory for erl_nif.h

# Prevent double-definition if two projects use this script
IF (NOT FindCouchbaseErlang_INCLUDED)

  INCLUDE (ParseArguments)

  IF (NOT ERLANG_FOUND)
    FIND_PROGRAM(ERLC_EXECUTABLE erlc)
    FIND_PROGRAM(ERL_EXECUTABLE erl)
    FIND_PROGRAM(DIALYZER_EXECUTABLE dialyzer)
    IF (ERLC_EXECUTABLE AND ERL_EXECUTABLE AND DIALYZER_EXECUTABLE)
      SET(ERLANG_FOUND True CACHE BOOL "Whether Erlang has been found")
      GET_FILENAME_COMPONENT(ERL_REAL_EXE ${ERL_EXECUTABLE} REALPATH)
      GET_FILENAME_COMPONENT(ERL_LOCATION ${ERL_REAL_EXE} PATH)

      SET(_erlang_exploded "${CMAKE_BINARY_DIR}/tlm/deps/erlang.exploded")

      FIND_PATH(ERL_NIF_INCLUDE_PATH erl_nif.h
                HINTS
                "${_erlang_exploded}/usr/include"
                "${ERL_LOCATION}/../usr/include"
                PATHS
                /usr/lib/erlang/usr/include
                /usr/local/lib/erlang/usr/include
                /opt/local/lib/erlang/usr/include
                /usr/lib64/erlang/usr/include)
      SET(ERLANG_INCLUDE_PATH "${ERL_NIF_INCLUDE_PATH}"
          CACHE STRING "Path to Erlang include files")

      MESSAGE(STATUS "Erlang runtime and compiler found in ${ERL_EXECUTABLE} and ${ERLC_EXECUTABLE}")
      MESSAGE(STATUS "Erlang dialyzer in ${DIALYZER_EXECUTABLE}")

      FIND_PROGRAM(PROVE_EXECUTABLE prove)
      IF (NOT PROVE_EXECUTABLE)
        MESSAGE (STATUS "prove testdriver not found - "
          "erlang testing unavailable")
      ENDIF (NOT PROVE_EXECUTABLE)

      FIND_PROGRAM(ESCRIPT_EXECUTABLE escript)
      IF (NOT ESCRIPT_EXECUTABLE)
        MESSAGE (STATUS "escript interpreter not found - "
          "rebar support will be unavailable")
      ELSE (NOT ESCRIPT_EXECUTABLE)
        MESSAGE(STATUS "Escript interpreter found in ${ESCRIPT_EXECUTABLE}")
      ENDIF (NOT ESCRIPT_EXECUTABLE)

      MESSAGE(STATUS "Erlang nif header in ${ERLANG_INCLUDE_PATH}")
    ELSE (ERLC_EXECUTABLE AND ERL_EXECUTABLE AND DIALYZER_EXECUTABLE)
      SET(ERLANG_FOUND False)
      IF (NOT ERL_EXECUTABLE)
        MESSAGE(STATUS "Erlang runtime (erl) not found")
      ENDIF (NOT ERL_EXECUTABLE)
      IF (NOT ERLC_EXECUTABLE)
        MESSAGE(STATUS "Erlang compiler (erlc) not found")
      ENDIF (NOT ERLC_EXECUTABLE)
      MESSAGE (FATAL_ERROR "Erlang not found - cannot continue building")
    ENDIF (ERLC_EXECUTABLE AND ERL_EXECUTABLE AND DIALYZER_EXECUTABLE)

    MARK_AS_ADVANCED(ERLANG_FOUND ERL_EXECUTABLE ERLC_EXECUTABLE ESCRIPT_EXECUTABLE ERLANG_INCLUDE_PATH)
  ENDIF (NOT ERLANG_FOUND)

  IF (ESCRIPT_EXECUTABLE AND NOT REBAR_SCRIPT)
    SET (_need_rebar_install TRUE)
  ELSEIF (REBAR_SCRIPT AND NOT EXISTS "${REBAR_SCRIPT}")
    MESSAGE(STATUS "Cached REBAR_SCRIPT ${REBAR_SCRIPT} no longer exists, reinstalling...")
    UNSET(REBAR_SCRIPT CACHE)
    SET (_need_rebar_install TRUE)
  ENDIF()

  IF (_need_rebar_install AND ESCRIPT_EXECUTABLE)
    MESSAGE(STATUS "rebar3 not found, installing via cbdep...")

    INCLUDE(CBDownloadDeps)

    # Get the erlang bin directory to add to PATH
    GET_FILENAME_COMPONENT(_escript_dir "${ESCRIPT_EXECUTABLE}" DIRECTORY)

    # Temporarily add erlang bin to PATH for rebar3 installation
    SET(_original_path "$ENV{PATH}")
    IF (WIN32)
      SET(ENV{PATH} "${_escript_dir};${_original_path}")
    ELSE ()
      SET(ENV{PATH} "${_escript_dir}:${_original_path}")
    ENDIF ()

    SET(_rebar_install_dir "${CMAKE_BINARY_DIR}/tlm/rebar3_install")

    # Get rebar3 version from manifest if available, otherwise use a default
    SET(_rebar_version "3.25.1")
    EXECUTE_PROCESS(
      COMMAND ${PYTHON_EXECUTABLE} tlm/scripts/get_manifest_annot.py REBAR3_VERSION
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      OUTPUT_VARIABLE _rebar_version_from_manifest
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    IF (_rebar_version_from_manifest)
      SET(_rebar_version "${_rebar_version_from_manifest}")
    ENDIF()

    MESSAGE(STATUS "Installing rebar3 version ${_rebar_version}")
    CBDEP_INSTALL(PACKAGE rebar3 VERSION ${_rebar_version} INSTALL_DIR "${_rebar_install_dir}")

    # Restore original PATH
    SET(ENV{PATH} "${_original_path}")

    SET(_rebar_script "${_rebar_install_dir}/rebar3-${_rebar_version}/bin/rebar3")
    IF (NOT EXISTS "${_rebar_script}")
      MESSAGE(WARNING "Failed to install rebar3 - expected at ${_rebar_script}")
      MESSAGE(STATUS "rebar support will be unavailable")
    ELSE()
      MESSAGE(STATUS "rebar3 installed successfully at ${_rebar_script}")
      SET (REBAR_SCRIPT "${_rebar_script}"
        CACHE STRING "Path to default rebar script")
    ENDIF()
  ENDIF()

  # Adds a target named <target> which runs "rebar compile" in the
  # current source directory, and a target named <target>-clean to run
  # "rebar clean". <target>-clean will be added as a dependency to
  # the <clean_hook> target (defaults to "realclean").
  #
  # If <eunit> is passed, a <target>-eunit target will be created that calls
  # "rebar compile_only=true eunit" to compile a separate version of the code
  # for tests only. <eunit_depends> will be added as dependencies to the eunit
  # target in addition to the regular dependencies passed via <depends>. Extra
  # options can be passed to rebar via <eunit_opts>.
  MACRO (Rebar)
    IF (NOT ESCRIPT_EXECUTABLE)
      MESSAGE (FATAL_ERROR "escript not found, therefore Rebar() "
        "cannot function.")
    ENDIF (NOT ESCRIPT_EXECUTABLE)

    PARSE_ARGUMENTS (Rebar "DEPENDS;REBAR_OPTS;EUNIT_OPTS;EUNIT_DEPENDS;EXTRA_ENV"
      "TARGET;COMMAND;REBAR_SCRIPT;CLEAN_HOOK"
      "NOCLEAN;NOALL;EUNIT" ${ARGN})

    SET (rebar_script "${REBAR_SCRIPT}")
    IF (Rebar_REBAR_SCRIPT)
      SET (rebar_script "${Rebar_REBAR_SCRIPT}")
    ENDIF (Rebar_REBAR_SCRIPT)

    IF (NOT EXISTS "${rebar_script}")
      MESSAGE (FATAL_ERROR "rebar script not found at ${rebar_script} - "
        "rebar support will not function. "
        "Set variable -DREBAR_SCRIPT to correct location to enable, "
        "or pass path using Rebar (... REBAR_SCRIPT /full/path)")
    ENDIF (NOT EXISTS "${rebar_script}")

    IF (NOT Rebar_CLEAN_HOOK)
      SET (Rebar_CLEAN_HOOK "realclean")
    ENDIF (NOT Rebar_CLEAN_HOOK)

    SET (_all ALL)
    IF (Rebar_NOALL)
      SET (_all "")
    ENDIF (Rebar_NOALL)

    IF (NOT Rebar_COMMAND)
      SET (Rebar_COMMAND "compile")
    ENDIF (NOT Rebar_COMMAND)

    get_filename_component(LIBSODIUM_LIB_DIR "${LIBSODIUM_LIBRARIES}" PATH)

    IF (APPLE)
        SET (_sysroot_arg "OSX_SYSROOT=${CMAKE_OSX_SYSROOT}")
    ENDIF (APPLE)

    # This is a hack to work around the problem with rebar CC invocation
    # when CC path contains a space
    IF (WIN32)
        SET (REBAR_CC cl.exe)
        SET (REBAR_CXX cl.exe)
    ELSE (WIN32)
        SET (REBAR_CC "${CMAKE_C_COMPILER}")
        SET (REBAR_CXX "${CMAKE_CXX_COMPILER}")
    ENDIF(WIN32)

    # This is a hack to work around problems with rebar3 dependency
    # management - it won't download the requested version of a
    # dependency's plugins if an older version of those plugins are
    # already cached, so we force it to use a cache directory in the
    # build dir so it's always clean.
    SET (REBAR3_CACHE_DIR "${CMAKE_BINARY_DIR}/tlm/rebar3_cache")
    FILE (MAKE_DIRECTORY "${REBAR3_CACHE_DIR}")

    # On Windows, rebar3 is an escript file that needs to be invoked through escript.
    # On macOS/Linux, the native build can be executed directly.
    IF (WIN32)
      SET(_rebar_cmd "${ESCRIPT_EXECUTABLE}" "${rebar_script}")
    ELSE ()
      SET(_rebar_cmd "${rebar_script}")
    ENDIF ()

    # Add Erlang bin directory to PATH so rebar3 can find erl
    # Compute Erlang bin directory from ERL_EXECUTABLE
    GET_FILENAME_COMPONENT(_erl_real_exe ${ERL_EXECUTABLE} REALPATH)
    GET_FILENAME_COMPONENT(_erlang_bin_dir ${_erl_real_exe} PATH)
    # Use --modify to prepend to PATH at runtime rather than expanding $ENV{PATH}
    # at configure time. This avoids issues on Windows where paths contain spaces
    # (e.g., "C:\Program Files\...") cause argument splitting.
    SET(_erlang_path_modify --modify "PATH=path_list_prepend:${_erlang_bin_dir}")

    ADD_CUSTOM_TARGET (${Rebar_TARGET} ${_all}
      "${CMAKE_COMMAND}" -E env
      ${_erlang_path_modify}
      CC=${REBAR_CC} CXX=${REBAR_CXX} REBAR_CACHE_DIR=${REBAR3_CACHE_DIR}
      ${_sysroot_arg}
      LIBSODIUM_INCLUDE_DIR=${LIBSODIUM_INCLUDE_DIR}
      LIBSODIUM_LIB_DIR=${LIBSODIUM_LIB_DIR}
      LIBSODIUM_LIBRARIES=${LIBSODIUM_LIBRARIES}
      ${Rebar_EXTRA_ENV}
      ${_rebar_cmd} ${Rebar_REBAR_OPTS}
      ${Rebar_COMMAND}
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" VERBATIM)

    IF (Rebar_EUNIT)
      SET(_eunit_target "${Rebar_TARGET}-eunit")
      ADD_CUSTOM_TARGET ("${_eunit_target}"
        "${CMAKE_COMMAND}" -E env
        ${_erlang_path_modify}
        CC=${REBAR_CC} CXX=${REBAR_CXX}
        ${_sysroot_arg}
        LIBSODIUM_INCLUDE_DIR=${LIBSODIUM_INCLUDE_DIR}
        LIBSODIUM_LIB_DIR=${LIBSODIUM_LIB_DIR}
        LIBSODIUM_LIBRARIES=${LIBSODIUM_LIBRARIES}
        ${Rebar_EXTRA_ENV}
        ${_rebar_cmd}
        as test compile ${Rebar_EUNIT_OPTS}
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" VERBATIM)

      # There's a bug in "rebar eunit" implementation: it doesn't generate
      # .erl files out of .xrl and .yrl files. The only workaround that I
      # found is to depend on the regular "rebar compile" target. That way the
      # latter generates all the sources that the former then can use.
      ADD_DEPENDENCIES (${_eunit_target} ${Rebar_TARGET})

      SET(_eunit_deps ${Rebar_DEPENDS} ${Rebar_EUNIT_DEPENDS})
      IF (_eunit_deps)
        ADD_DEPENDENCIES (${_eunit_target} ${_eunit_deps})
      ENDIF (_eunit_deps)
    ENDIF (Rebar_EUNIT)

    IF (Rebar_DEPENDS)
      ADD_DEPENDENCIES (${Rebar_TARGET} ${Rebar_DEPENDS})
    ENDIF (Rebar_DEPENDS)

    IF (NOT Rebar_NOCLEAN)
      ADD_CUSTOM_TARGET ("${Rebar_TARGET}-clean"
        "${CMAKE_COMMAND}" -E env
        ${_erlang_path_modify}
        CC=${REBAR_CC} CXX=${REBAR_CXX}
        ${Rebar_EXTRA_ENV}
        ${_rebar_cmd} clean
        COMMAND "${CMAKE_COMMAND}" -E remove_directory _build
        COMMAND "${CMAKE_COMMAND}" -E remove_directory .eunit
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" VERBATIM)

      IF (TARGET ${Rebar_CLEAN_HOOK})
        ADD_DEPENDENCIES (${Rebar_CLEAN_HOOK} "${Rebar_TARGET}-clean")
      ENDIF (TARGET ${Rebar_CLEAN_HOOK})
    ENDIF (NOT Rebar_NOCLEAN)

  ENDMACRO (Rebar)

  # macro to a a directory to the Erlang include directories
  MACRO(ADD_ERLANG_INCLUDE_DIR dir)
    SET(ERLANG_INCLUDE_DIR ${ERLANG_INCLUDE_DIR} -I ${dir})
  ENDMACRO(ADD_ERLANG_INCLUDE_DIR)

  # macro to compile erlang files
  MACRO (ERL_BUILD)
    PARSE_ARGUMENTS (Erl "SOURCES;DEPENDS" "APPNAME" "" ${ARGN})
    SET(outfiles)
    SET(AppName ${Erl_APPNAME})
    GET_FILENAME_COMPONENT(EBIN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ebin" ABSOLUTE)
    IF (IS_DIRECTORY ${EBIN_DIR})
      SET(${AppName}_ebin ${EBIN_DIR})
    ELSE (IS_DIRECTORY ${EBIN_DIR})
      SET(${AppName}_ebin ${CMAKE_CURRENT_BINARY_DIR})
    ENDIF (IS_DIRECTORY ${EBIN_DIR})

    IF (ERLANG_INCLUDE_DIR)
      SET(ERLANG_INCLUDES ${ERLANG_INCLUDE_DIR})
    ENDIF (ERLANG_INCLUDE_DIR)

    SET(${AppName}_src ${CMAKE_CURRENT_SOURCE_DIR})

    #Set application modules
    SET(${AppName}_module_list)

    FOREACH (it ${Erl_SOURCES})
      GET_FILENAME_COMPONENT(outfile ${it} NAME_WE)
      GET_FILENAME_COMPONENT(outfile_ext ${it} EXT)
      SET(${AppName}_module_list ${${AppName}_module_list} "'${outfile}'")
      IF (${outfile_ext} STREQUAL ".asn" OR ${outfile_ext} STREQUAL ".ASN")
        SET(outfile
          ${${AppName}_ebin}/${outfile}.erl
          ${${AppName}_ebin}/${outfile}.hrl
          ${${AppName}_ebin}/${outfile}.asn1db
          ${${AppName}_ebin}/${outfile}.beam)
      ELSE(${outfile_ext} STREQUAL ".asn" OR ${outfile_ext} STREQUAL ".ASN")
        SET(outfile
          ${${AppName}_ebin}/${outfile}.beam)
      ENDIF(${outfile_ext} STREQUAL ".asn" OR ${outfile_ext} STREQUAL ".ASN")
      SET(outfiles ${outfiles} ${outfile})
      GET_FILENAME_COMPONENT(it ${it} ABSOLUTE)
      ADD_CUSTOM_COMMAND(
        OUTPUT ${outfile}
        COMMAND ${ERLC_EXECUTABLE} -o ${${AppName}_ebin} ${ERLANG_INCLUDES} ${ERLANG_COMPILE_FLAGS} ${it}
        DEPENDS ${it} ${Erl_DEPENDS}
        VERBATIM)
    ENDFOREACH(it)
    ADD_CUSTOM_TARGET(${AppName} ALL DEPENDS ${outfiles})
  ENDMACRO (ERL_BUILD)

  MACRO (ERL_BUILD_OTP)
    PARSE_ARGUMENTS (Otp
      "HEADERS;SOURCES;DEPENDS" "APPNAME;VERSION;INSTALL_PATH" "" ${ARGN})

    SET(outfiles)
    SET(AppName ${Otp_APPNAME})
    FILE(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/ebin)
    SET(${AppName}_ebin ${CMAKE_CURRENT_BINARY_DIR}/ebin)
    SET(${AppName}_install "${Otp_INSTALL_PATH}/${AppName}-${Otp_VERSION}")

    IF (Otp_HEADERS)
      ADD_ERLANG_INCLUDE_DIR(${CMAKE_CURRENT_SOURCE_DIR}/include)
      # Copy the headers into the build dir in order to be able to use those
      # dir for running the unit tests against. They need proper OTP apps.
      FILE(COPY ${Otp_HEADERS} DESTINATION
        "${CMAKE_CURRENT_BINARY_DIR}/include")
      INSTALL(FILES ${Otp_HEADERS} DESTINATION "${${AppName}_install}/include")
    ENDIF (Otp_HEADERS)

    IF (ERLANG_INCLUDE_DIR)
      SET(ERLANG_INCLUDES ${ERLANG_INCLUDE_DIR})
    ENDIF (ERLANG_INCLUDE_DIR)

    SET(${AppName}_src "${CMAKE_CURRENT_SOURCE_DIR}/src")
    CONFIGURE_FILE("${${AppName}_src}/${AppName}.app.src"
      "${${AppName}_ebin}/${AppName}.app")

    #Set application modules
    SET(${AppName}_module_list)

    FOREACH (it ${Otp_SOURCES})
      GET_FILENAME_COMPONENT(outfile ${it} NAME_WE)
      GET_FILENAME_COMPONENT(outfile_ext ${it} EXT)
      SET(${AppName}_module_list ${${AppName}_module_list} "'${outfile}'")
      IF (${outfile_ext} STREQUAL ".asn" OR ${outfile_ext} STREQUAL ".ASN")
        SET(outfile
          ${${AppName}_ebin}/${outfile}.erl
          ${${AppName}_ebin}/${outfile}.hrl
          ${${AppName}_ebin}/${outfile}.asn1db
          ${${AppName}_ebin}/${outfile}.beam)
      ELSE(${outfile_ext} STREQUAL ".asn" OR ${outfile_ext} STREQUAL ".ASN")
        SET(outfile
          ${${AppName}_ebin}/${outfile}.beam)
      ENDIF(${outfile_ext} STREQUAL ".asn" OR ${outfile_ext} STREQUAL ".ASN")
      SET(outfiles ${outfiles} ${outfile})
      GET_FILENAME_COMPONENT(it ${it} ABSOLUTE)
      ADD_CUSTOM_COMMAND(
        OUTPUT ${outfile}
        COMMAND ${ERLC_EXECUTABLE} -o ${${AppName}_ebin} ${ERLANG_INCLUDES} ${ERLANG_COMPILE_FLAGS} ${it}
        DEPENDS ${it} ${Otp_DEPENDS}
        VERBATIM)
    ENDFOREACH(it)
    ADD_CUSTOM_TARGET(${AppName} ALL DEPENDS ${outfiles})

    INSTALL(FILES ${outfiles} "${${AppName}_ebin}/${AppName}.app"
        DESTINATION "${${AppName}_install}/ebin")
  ENDMACRO (ERL_BUILD_OTP)

  SET (FindCouchbaseErlang_INCLUDED 1)
ENDIF (NOT FindCouchbaseErlang_INCLUDED)
