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

INCLUDE (CBDownloadDeps)

# Our desired tool versions.
SET (MINICONDA_VERSION 4.6.14)
SET (CONSTRUCTOR_VERSION 2.3.0)
STRING (REGEX REPLACE "-.*" "" CB_VERSION "${PRODUCT_VERSION}")

# Count to differentiate different versions of cbpy over time.
# Increase this number whenever changes are made to 'construct.yaml'
# so that cbpy will be re-installed into the install/lib/python/runtime
# directory, and the MacOS wrapper script will install cbpy into a
# differently-named directory in the user's home dir.
SET (CBPY_BLD_NUM 1 CACHE INTERNAL "")

# Set up various paths and locations for Python-related things:

# Base directory for cbpy install - used by out-of-build programs such
# as the non-installed wrapper scripts created by PyWrapper(). Note that
# this directory is actually created by the local-cbpy target below.
SET (CBPY_PATH lib/python/runtime)
SET (CBPY_INSTALL "${CMAKE_INSTALL_PREFIX}/${CBPY_PATH}" CACHE INTERNAL "")
SET (CBPY_VER_FILE "${CBPY_INSTALL}/couchbase-${CB_VERSION}-py${CBPY_BLD_NUM}.version")

# Path to python interpreter in the local cbpy install.
IF (WIN32)
  SET (_localpy "${CBPY_INSTALL}/python3.exe")
ELSE ()
  SET (_localpy "${CBPY_INSTALL}/bin/python3")
ENDIF ()
SET (PYTHON_EXE "${_localpy}" CACHE INTERNAL "Path to python interpreter")

# Add the PyWrapper-related CMake functions.
INCLUDE (PyWrapperFunctions.cmake)

# Target to download and install stock Miniconda3. This python
# installation is used ONLY to install Constructor, which is then
# used to build our bespoke cbpy installer.

SET (_miniconda_install "${CMAKE_CURRENT_BINARY_DIR}/miniconda3-${MINICONDA_VERSION}")
IF (WIN32)
  SET (_pyexe "${_miniconda_install}/python.exe")
  SET (_condaexe "${_miniconda_install}/Scripts/conda.exe")
  SET (_condapath "Scripts")
ELSE ()
  SET (_pyexe "${_miniconda_install}/bin/python")
  SET (_condaexe "${_miniconda_install}/bin/conda")
  SET (_condapath "bin")
ENDIF ()
SET (CONDA_EXE "${_condaexe}" CACHE INTERNAL "Path to conda program")

ADD_CUSTOM_COMMAND (OUTPUT "${CONDA_EXE}"
  COMMENT "Creating Miniconda3 ${MINICONDA_VERSION} install"
  COMMAND "${CMAKE_COMMAND}" -E remove_directory "${_miniconda_install}"
  COMMAND "${CBDEP}" install -d "${CMAKE_CURRENT_BINARY_DIR}"
      miniconda3 ${MINICONDA_VERSION}
  COMMAND "${_miniconda_install}/${_condapath}/conda" config --set auto_update_conda False
  VERBATIM)

ADD_CUSTOM_TARGET(miniconda3 ALL DEPENDS "${CONDA_EXE}")

# Target to add constructor to the global Miniconda installation

GET_FILENAME_COMPONENT (_pydir "${CONDA_EXE}" DIRECTORY)
SET (_constructor "${_pydir}/constructor")
IF (WIN32)
  SET (_constructor "${_constructor}.exe")
ENDIF ()

# Invoke conda to install constructor. Note: on Docker swarm slaves, the
# build environment is launched via sudo. This breaks conda for dumb
# reasons (https://github.com/conda/conda/issues/7267). Workaround is
# to unset SUDO_UID when invoking.
ADD_CUSTOM_COMMAND (OUTPUT "${_constructor}"
  COMMENT "Installing Anaconda Constructor"
  DEPENDS miniconda3
  COMMAND "${CMAKE_COMMAND}" -E env --unset=SUDO_UID
    "${CONDA_EXE}" install -y constructor=${CONSTRUCTOR_VERSION}
  VERBATIM)

# Target to create our "microconda" installer
SET (_installer "${CMAKE_CURRENT_BINARY_DIR}/cbpy-installer")
IF (WIN32)
  SET (_installer "${_installer}.exe")
ELSE ()
  SET (_installer "${_installer}.sh")
ENDIF ()

# Workaround for https://github.com/conda/conda/issues/8046 - conda depends
# on openssl, but the openssl libs are tucked away in a subdirectory.
# Recommended solution is to activate the conda environment, which sets
# PATH and friends, but that doesn't really work for firing off commands from
# CMake. Fortunately this only appears to be a problem on Windows, and Windows
# will also look for libs in the current working directory. So, a hack / fix
# for this issue is to cd into Library\bin prior to running constructor.
IF (WIN32)
  SET (_cwd "${_miniconda_install}/Library/bin")
ELSE ()
  SET (_cwd ".")
ENDIF ()

ADD_CUSTOM_COMMAND (OUTPUT "${_installer}"
  COMMAND "${_constructor}" "${CMAKE_CURRENT_SOURCE_DIR}"
  WORKING_DIRECTORY "${_cwd}"
  COMMAND "${CMAKE_COMMAND}" -E rename cbpy-installer "${_installer}"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/construct.yaml" "${_constructor}"
  COMMENT "Build cbpy distribution"
  VERBATIM)

ADD_CUSTOM_TARGET (cbpy-installer ALL DEPENDS "${_installer}")
INSTALL (FILES "${_installer}" DESTINATION lib/python)

# Target to create local installation of our "microconda"
# in the install directory. Custom command depends on both the previous
# 'cbpy-installer' target as well as on the actual cbpy-installer file,
# so that updating construct.yaml will both rebuild cbpy-installer AND
# re-install it.

IF (WIN32)
  FILE (TO_NATIVE_PATH "${_installer}" _wininstaller)
  FILE (TO_NATIVE_PATH "${CBPY_INSTALL}" _wincbpy)
  ADD_CUSTOM_COMMAND (OUTPUT "${CBPY_VER_FILE}"
    COMMENT "Installing local cbpy"
    DEPENDS cbpy-installer "${_installer}"
    COMMAND cmd /c start /wait
      "${_wininstaller}" /NoRegistry=1 /S "/D=${_wincbpy}"
    COMMAND "${CMAKE_COMMAND}" -E touch "${CBPY_VER_FILE}"
    VERBATIM)
ELSE ()
  ADD_CUSTOM_COMMAND (OUTPUT "${CBPY_VER_FILE}"
    COMMENT "Installing local cbpy"
    DEPENDS cbpy-installer "${_installer}"
    COMMAND "${_installer}" -u -b -p "${CBPY_INSTALL}"
    COMMAND "${CMAKE_COMMAND}" -E touch "${CBPY_VER_FILE}"
    VERBATIM)
ENDIF()

ADD_CUSTOM_TARGET (local-cbpy ALL DEPENDS "${CBPY_VER_FILE}")

# Clean targets

ADD_CUSTOM_TARGET ("miniconda3-clean"
  COMMAND "${CMAKE_COMMAND}" -E remove_directory "${_miniconda_install}"
  VERBATIM)

ADD_CUSTOM_TARGET ("cbpy-installer-clean"
  COMMAND "${CMAKE_COMMAND}" -E remove "${_installer}"
  VERBATIM)

ADD_CUSTOM_TARGET ("local-cbpy-clean"
  COMMAND "${CMAKE_COMMAND}" -E remove_directory "${CBPY_INSTALL}"
  VERBATIM)

ADD_DEPENDENCIES (realclean miniconda3-clean cbpy-installer-clean local-cbpy-clean)
