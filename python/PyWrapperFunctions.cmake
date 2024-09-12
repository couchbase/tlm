#
#     Copyright 2019 Couchbase, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Provides CMake functions for installing Python 3 programs. This works
# in conjunction with the targets in tlm/python/CMakeLists.txt which
# install a local Python and build a bespoke Python installer for
# shipping with Couchbase Server.

# Have to remember the directory containing this file in a cached variable,
# so it can be recalled when the functions are invoked from elsewhere in
# the build.
SET (TLM_PYTHON_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "")

# Creates a wrapper script from a template, in an OS-specific manner.
# Note: OUTPUT_FILE should be an absolute path to a file with no extension.
# On Linux and MacOS, the resulting file will be named as such with no
# extension. On Windows, the resulting file will have a .exe extension,
# built from py-wrapper.c.
FUNCTION (ConfigureWrapper CODE_REL_ARG LIB_REL_ARG PY_REL_ARG OUTPUT_FILE)
  IF (WIN32)
    SET (_wrapper py-wrapper.c)
  ELSE ()
    IF (APPLE)
      SET (LIB_PATH_VAR DYLD_LIBRARY_PATH)
    ELSE ()
      SET (LIB_PATH_VAR LD_LIBRARY_PATH)
    ENDIF ()
    SET (_wrapper py-wrapper.sh)
  ENDIF ()

  # CMake is weird - need to create our own "local" versions of formal args
  SET (CODE_REL "${CODE_REL_ARG}")
  SET (LIB_REL "${LIB_REL_ARG}")
  SET (PY_REL "${PY_REL_ARG}")

  # Convert any absolute paths to relative
  IF (IS_ABSOLUTE "${CODE_REL}")
    FILE (RELATIVE_PATH CODE_REL "${OUTPUT_FILE}/.." "${CODE_REL}")
  ENDIF ()
  IF (IS_ABSOLUTE "${LIB_REL}")
    FILE (RELATIVE_PATH LIB_REL "${OUTPUT_FILE}/.." "${LIB_REL}")
  ENDIF ()
  IF (IS_ABSOLUTE "${PY_REL}")
    FILE (RELATIVE_PATH PY_REL "${OUTPUT_FILE}/.." "${PY_REL}")
  ENDIF ()

  # Have to use OS-native paths
  FILE (TO_NATIVE_PATH "${CODE_REL}" CODE_REL)
  FILE (TO_NATIVE_PATH "${LIB_REL}" LIB_REL)
  FILE (TO_NATIVE_PATH "${PY_REL}" PY_REL)

  # And Windows sucks
  IF (WIN32)
    STRING (REPLACE "\\" "\\\\" CODE_REL "${CODE_REL}")
    STRING (REPLACE "\\" "\\\\" LIB_REL "${LIB_REL}")
    STRING (REPLACE "\\" "\\\\" PY_REL "${PY_REL}")
  ENDIF (WIN32)

  IF (WIN32)
    SET (_output "${OUTPUT_FILE}.c")
  ELSE ()
    SET (_output "${OUTPUT_FILE}")
  ENDIF ()

  CONFIGURE_FILE (
    "${TLM_PYTHON_DIR}/${_wrapper}.tmpl"
    "${_output}"
    @ONLY
  )

  # Windows-specific compilation target
  IF (WIN32)
    GET_FILENAME_COMPONENT (_output_name "${OUTPUT_FILE}" NAME)
    ADD_EXECUTABLE ("${_output_name}" "${_output}")
    # Ensure in expected output directory
    GET_FILENAME_COMPONENT (_output_dir "${OUTPUT_FILE}" DIRECTORY)
    SET_TARGET_PROPERTIES ("${_output_name}" PROPERTIES
      RUNTIME_OUTPUT_DIRECTORY "${_output_dir}")
  ENDIF ()

ENDFUNCTION (ConfigureWrapper)

# Create the master wrapper script for PyWrapper(), since all installed
# programs can use the same one (same relative paths from wrapper script
# to the code, libs, and python)
SET (_masterpy "${CMAKE_CURRENT_BINARY_DIR}/install-py-wrapper")
ConfigureWrapper (../lib/python ../lib ../${CBPY_PATH} "${_masterpy}")
IF (WIN32)
  SET (_masterpy "${_masterpy}.exe")
ENDIF ()
SET (MASTER_PY_WRAPPER "${_masterpy}" CACHE INTERNAL "")

INCLUDE (ParseArguments)

# Installs Python scripts into lib/python, and creates a wrapper in bin/
# for executing them with the bundled Anaconda Python installation.
#
# Required arguments:
#
# SCRIPTS - name(s) of python script(s). This is assumed to be a bare
#   filename, eg. "myscript", not "myscript.py".
#
# Optional arguments:
#
# EXTRA_SCRIPTS - list of additional python scripts to add to
#   lib/python.
#
# ADD_TO_STANDALONE_PACKAGE - list of extra standalone packages (eg.
#   admin_tools) to add this script to. This will also arrange for
#   Python to be copied into the corresponding package.
#
# BUILD_DIR - absolute path to directory in build tree to also create a
#   wrapper script in. If specified, a custom wrapper will be created
#   for each named script.
FUNCTION (PyWrapper)
  PARSE_ARGUMENTS (
    Py "SCRIPTS;ADD_TO_STANDALONE_PACKAGE;EXTRA_SCRIPTS"
    "BUILD_DIR" "" ${ARGN}
  )

  IF (NOT Py_SCRIPTS)
    MESSAGE (FATAL_ERROR "SCRIPTS is required!")
  ENDIF ()

  FOREACH (_script ${Py_SCRIPTS})
    # Determine wrapper script name
    GET_FILENAME_COMPONENT (_scriptname "${_script}" NAME)
    IF (WIN32)
      SET (_installname "${_scriptname}.exe")
    ELSE ()
      SET (_installname "${_scriptname}")
    ENDIF ()

    # Install the script, wrapper script, and extra scripts into each
    # requested root
    FOREACH (pkg "" ${Py_ADD_TO_STANDALONE_PACKAGE})
      # Slightly different args for primary component and extra packages
      IF (pkg STREQUAL "")
        SET (_root "")
        SET (_component_args)
      ELSE ()
        MESSAGE (STATUS "Adding ${_script} to ${pkg} package")
        # The trailing / is important for forming correct paths later
        SET (_root "${${pkg}_INSTALL_PREFIX}/")
        SET (_component_args EXCLUDE_FROM_ALL COMPONENT ${pkg})

        # Also install python into pkg root at lib/python/
        INSTALL (
          DIRECTORY "${CBPY_INSTALL}"
          DESTINATION "${_root}lib/python"
          USE_SOURCE_PERMISSIONS
          ${_component_args}
        )
      ENDIF ()

      # Install the script itself into lib/python
      INSTALL (
        PROGRAMS ${Py_SCRIPTS}
        DESTINATION "${_root}lib/python"
        ${_component_args}
      )

      # Install extra scripts into lib/python
      IF (Py_EXTRA_SCRIPTS)
        INSTALL (
          FILES ${Py_EXTRA_SCRIPTS}
          DESTINATION "${_root}lib/python"
          ${_component_args})
      ENDIF ()

      # Install a copy of the master wrapper script into bin
      INSTALL (
        PROGRAMS "${MASTER_PY_WRAPPER}"
        DESTINATION "${_root}bin"
        RENAME "${_installname}"
        ${_component_args}
      )
    ENDFOREACH (pkg)

    IF (Py_BUILD_DIR)
      GET_FILENAME_COMPONENT (_scriptdir "${_script}/.." ABSOLUTE)

      ConfigureWrapper (
        "${_scriptdir}"
        "${CMAKE_INSTALL_PREFIX}/lib"
        "${CBPY_INSTALL}"
        "${Py_BUILD_DIR}/${_scriptname}"
      )
    ENDIF ()
  ENDFOREACH ()

ENDFUNCTION (PyWrapper)
