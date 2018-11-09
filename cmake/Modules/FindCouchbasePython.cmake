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
    SET (_pypip "${_pybindir}/pip.exe")
    SET (_pypipenv "${_pybindir}/pipenv.exe")
  ELSE ()
    SET (PYTHON_VENV "${PROJECT_BINARY_DIR}/tlm/python.venv/python${PYTHON_VERSION}")
    SET (_pybindir "${PYTHON_VENV}/bin")
    SET (_pyexe "${_pybindir}/python")
    SET (_pypip "${_pybindir}/pip")
    SET (_pypipenv "${_pybindir}/pipenv")
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

    # Have to use "python -m pip" here rather than invoking "pip" directly,
    # as the later chokes on Windows
    EXECUTE_PROCESS (
      COMMAND "${_pyexe}" -m pip install -U pip pipenv
      RESULT_VARIABLE _pip_result
      OUTPUT_VARIABLE _pip_out
      ERROR_VARIABLE _pip_out
    )
    IF (_pip_result)
      FILE (REMOVE_RECURSE "${PYTHON_VENV}")
      MESSAGE (FATAL_ERROR "Failed to create Python venv: ${_pip_out}")
    ENDIF ()
  ENDIF ()

  SET (PYTHON_EXE "${_pyexe}" CACHE INTERNAL "Path to python interpretter")
  SET (PYTHON_PIPENV "${_pypipenv}" CACHE INTERNAL "Path to pipenv")
  MESSAGE (STATUS "Using Python ${PYTHON_VERSION} from ${PYTHON_EXE}")

  # Have to remember cwd when this find is INCLUDE()d
  SET (TLM_MODULES_DIR "${CMAKE_CURRENT_LIST_DIR}")

  INCLUDE (ParseArguments)

  # Adds a target which builds an executable from a Python program
  # using PyInstaller. It is assumed that the current directory is
  # a valid pipenv project, ie, it contains a Pipfile and Pipfile.lock.
  #
  # Required arguments:
  #
  # TARGET - name of CMake target
  #
  # SCRIPT - Python script
  #
  # OUTPUT - name of output binary (will be created in CMAKE_CURRENT_BINARY_DIR)
  #
  # Optional arguments:
  #
  # INSTALL_PATH - creates a CMake INSTALL() directive to install the OUTPUT
  # into CMAKE_INSTALL_PREFIX in a directory with this name
  #
  # DEPENDS - list of files (other than SCRIPT, Pipfile, and Pipfile.lock)
  # that should cause this target to re-run if they are newer than OUTPUT.
  # May also list CMake targets that must be executed prior to this one.
  MACRO (PyInstall)

    PARSE_ARGUMENTS (Py "DEPENDS"
      "TARGET;OUTPUT;SCRIPT;INSTALL_PATH"
      "" ${ARGN})

    IF (NOT Py_TARGET)
      MESSAGE (FATAL_ERROR "TARGET is required!")
    ENDIF ()
    IF (NOT Py_OUTPUT)
      MESSAGE (FATAL_ERROR "OUTPUT is required!")
    ENDIF ()
    IF (NOT Py_SCRIPT)
      MESSAGE (FATAL_ERROR "SCRIPT is required!")
    ENDIF ()

    # Local output file
    SET (_pyoutput "${CMAKE_CURRENT_BINARY_DIR}/${Py_OUTPUT}")

    ADD_CUSTOM_COMMAND (OUTPUT "${_pyoutput}"
      COMMAND "${CMAKE_COMMAND}"
        -D "PYTHON_PIPENV=${PYTHON_PIPENV}"
        -D "BUILD_DIR=${CMAKE_CURRENT_BINARY_DIR}/${Py_TARGET}.pyinstaller"
        -D "SCRIPTFILE=${CMAKE_CURRENT_SOURCE_DIR}/${Py_SCRIPT}"
        -D "OUTPUT=${Py_OUTPUT}"
        -P "${TLM_MODULES_DIR}/py-install.cmake"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
      MAIN_DEPENDENCY "${Py_SCRIPT}"
      DEPENDS ${Py_DEPENDS}
        "${CMAKE_CURRENT_SOURCE_DIR}/Pipfile"
        "${CMAKE_CURRENT_SOURCE_DIR}/Pipfile.lock"
      COMMENT "Building Python target ${Py_TARGET} using Python ${PYTHON_VERSION}"
      VERBATIM)

    # Python target
    ADD_CUSTOM_TARGET ("${Py_TARGET}" ALL DEPENDS "${_pyoutput}")

    # Install directive
    IF (Py_INSTALL_PATH)
      INSTALL (PROGRAMS "${_pyoutput}" DESTINATION "${Py_INSTALL_PATH}")
    ENDIF ()
    MESSAGE (STATUS "Added Python build target '${Py_TARGET}'")

  ENDMACRO (PyInstall)
ENDIF (NOT DEFINED COUCHBASE_PYTHON_INCLUDED)