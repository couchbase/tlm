#
#     Copyright 2018 Couchbase, Inc.
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

# Installs a local fixed Python interpretter, and provides a CMake function
# to create a standalone executable using PyInstaller.

# Note: This file should eventually replace FindCouchbasePythonInterp.cmake.

IF (NOT DEFINED COUCHBASE_PYTHON_INCLUDED)
  SET (COUCHBASE_PYTHON_INCLUDED 1)
  SET (PYTHON_VERSION 3.6.6)
  # Expected output files - might not exist yet
  IF (WIN32)
    SET (PYTHON_VENV "${PROJECT_BINARY_DIR}/tlm/python.venv/python${PYTHON_VERSION}-amd64")
    SET (_pybindir "${PYTHON_VENV}/Scripts")
    SET (_pyexe "${_pybindir}/python.exe")
  ELSE ()
    SET (PYTHON_VENV "${PROJECT_BINARY_DIR}/tlm/python.venv/python${PYTHON_VERSION}")
    SET (_pybindir "${PYTHON_VENV}/bin")
    SET (_pyexe "${_pybindir}/python")
  ENDIF ()

  IF (NOT EXISTS "${PYTHON_VENV}")
    MESSAGE (STATUS "Creating Python ${PYTHON_VERSION} venv")
    EXECUTE_PROCESS (
      COMMAND "${CBDEP}" install
        -d "${PROJECT_BINARY_DIR}/tlm/python.venv"
        python ${PYTHON_VERSION}
      RESULT_VARIABLE _cbdep_result
      OUTPUT_VARIABLE _cbdep_out
      ERROR_VARIABLE _cbdep_out
    )
    IF (_cbdep_result)
      FILE (REMOVE_RECURSE "${PYTHON_VENV}")
      MESSAGE (FATAL_ERROR "Failed to create Python venv: ${_cbdep_out}")
    ENDIF ()

  ENDIF ()

  SET (PYTHON_EXE "${_pyexe}" CACHE INTERNAL "Path to python interpretter")
  SET (ENV{VIRTUAL_ENV} "${PYTHON_VENV}")
  MESSAGE (STATUS "Using Python ${PYTHON_VERSION} from ${PYTHON_EXE}")

  # Have to remember cwd when this find is INCLUDE()d
  SET (TLM_MODULES_DIR "${CMAKE_CURRENT_LIST_DIR}")

  INCLUDE (ParseArguments)

  # Adds a target which builds an executable from a Python program
  # using PyInstaller. It is assumed that the current directory
  # contains a requirements.txt.
  #
  # Required arguments:
  #
  # TARGET - name of CMake target
  #
  # SCRIPT - Python script
  #
  # Optional arguments:
  #
  # OUTPUT - name of output binary (will be created in CMAKE_CURRENT_BINARY_DIR)
  # (default value is same as TARGET)
  #
  # INSTALL_PATH - creates a CMake INSTALL() directive to install the OUTPUT
  # into CMAKE_INSTALL_PREFIX in a directory with this name
  #
  # DEPENDS - list of files (other than SCRIPT, Pipfile, and Pipfile.lock)
  # that should cause this target to re-run if they are newer than OUTPUT.
  # May also list CMake targets that must be executed prior to this one.
  #
  # IMPORTS - list of python packages that the script imports. PyInstaller can
  # normally introspect this, but there are occasions when it cannot; you can
  # add extra ones here as necessary.
  #
  # EXTRA_BIN - list of extra binaries to include in the resulting binary

  MACRO (PyInstall)

    PARSE_ARGUMENTS (Py "DEPENDS;IMPORTS;LIBRARY_DIRS;EXTRA_BIN"
      "TARGET;OUTPUT;SCRIPT;INSTALL_PATH"
      "" ${ARGN})

    IF (NOT Py_TARGET)
      MESSAGE (FATAL_ERROR "TARGET is required!")
    ENDIF ()
    IF (NOT Py_OUTPUT)
      SET (Py_OUTPUT ${Py_TARGET})
    ENDIF ()
    IF (NOT Py_SCRIPT)
      MESSAGE (FATAL_ERROR "SCRIPT is required!")
    ENDIF ()

    # Local output file and build directory
    SET (_pyoutput "${CMAKE_CURRENT_BINARY_DIR}/${Py_OUTPUT}")
    SET (_pyinstallerdir "${CMAKE_CURRENT_BINARY_DIR}/${Py_TARGET}.pyinstaller")
    SET (_pyvenv "${CMAKE_CURRENT_BINARY_DIR}/pyvenv")
    GET_FILENAME_COMPONENT (_dirname "${CMAKE_CURRENT_SOURCE_DIR}" NAME)
    ADD_CUSTOM_COMMAND (OUTPUT "${_pyoutput}"
      COMMAND "${CMAKE_COMMAND}"
        -D "VENV_DIR=${_pyvenv}"
        -D "BUILD_DIR=${_pyinstallerdir}"
        -D "SCRIPTFILE=${CMAKE_CURRENT_SOURCE_DIR}/${Py_SCRIPT}"
        -D "HIDDENIMPORTS=${Py_IMPORTS}"
        -D "LIBRARY_DIRS=${Py_LIBRARY_DIRS}"
        -D "EXTRA_BIN=${Py_EXTRA_BIN}"
        -D "OUTPUT=${Py_OUTPUT}"
        -P "${TLM_MODULES_DIR}/py-install.cmake"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
      MAIN_DEPENDENCY "${Py_SCRIPT}"
      DEPENDS ${Py_DEPENDS}
        "${CMAKE_CURRENT_SOURCE_DIR}/requirements.txt"
        "${_dirname}-venv"
      COMMENT "Building Python target ${Py_TARGET} using Python ${PYTHON_VERSION}"
      VERBATIM)

    # Python target
    ADD_CUSTOM_TARGET ("${Py_TARGET}" ALL DEPENDS "${_pyoutput}")

    # Clean target
    ADD_CUSTOM_TARGET ("${Py_TARGET}-clean"
      COMMAND "${CMAKE_COMMAND}" -E remove "${_pyoutput}"
      COMMAND "${CMAKE_COMMAND}" -E remove_directory "${_pyinstallerdir}")
    ADD_DEPENDENCIES (realclean "${Py_TARGET}-clean")

    # Install directive
    IF (Py_INSTALL_PATH)
      INSTALL (PROGRAMS "${_pyoutput}" DESTINATION "${Py_INSTALL_PATH}")
    ENDIF ()
    MESSAGE (STATUS "Added Python build target '${Py_TARGET}'")

  ENDMACRO (PyInstall)

  # Adds a target which initializes a Python venv. It is assumed that the
  # current directory contains a requirements.txt.
  #
  # Required arguments:
  #
  #   (none)
  #
  # Optional arguments:
  #
  # DEPENDS - list of files (other than SCRIPT, Pipfile, and Pipfile.lock)
  # that should cause this target to re-run if they are newer than OUTPUT.
  # May also list CMake targets that must be executed prior to this one.
  #
  # LIBRARY_DIRS, INCLUDE_DIRS - lists of directories where C-linkage pip
  # requirements may look for libraries / header files.

  MACRO (PyVenv)

    PARSE_ARGUMENTS (Py "DEPENDS;LIBRARY_DIRS;INCLUDE_DIRS"
      "TARGET"
      "" ${ARGN})

    # Local output file and build directory
    SET (_pyvenv "${CMAKE_CURRENT_BINARY_DIR}/pyvenv")
    SET (_pyvenvoutput "${_pyvenv}/created")
    GET_FILENAME_COMPONENT (_dirname "${CMAKE_CURRENT_SOURCE_DIR}" NAME)
    ADD_CUSTOM_COMMAND (OUTPUT "${_pyvenvoutput}"
      COMMAND "${CMAKE_COMMAND}"
        -D "PYTHON_EXE=${PYTHON_EXE}"
        -D "VENV_DIR=${_pyvenv}"
        -D "LIBRARY_DIRS=${Py_LIBRARY_DIRS}"
        -D "INCLUDE_DIRS=${Py_INCLUDE_DIRS}"
        -P "${TLM_MODULES_DIR}/py-venv.cmake"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
      DEPENDS ${Py_DEPENDS}
        "${CMAKE_CURRENT_SOURCE_DIR}/requirements.txt"
      COMMENT "Building Python venv ${_dirname} using Python ${PYTHON_VERSION}"
      VERBATIM)

    # Venv target
    ADD_CUSTOM_TARGET ("${_dirname}-venv" ALL DEPENDS "${_pyvenvoutput}")

    # Clean target
    ADD_CUSTOM_TARGET ("${_dirname}-venv-clean"
      COMMAND "${CMAKE_COMMAND}" -E remove_directory "${_pyvenv}")
    ADD_DEPENDENCIES (realclean "${_dirname}-venv-clean")

  ENDMACRO (PyVenv)

ENDIF (NOT DEFINED COUCHBASE_PYTHON_INCLUDED)