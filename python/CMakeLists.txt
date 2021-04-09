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

# The version of cbpy. Must match the entries in tlm/deps/manifest.cmake.
# The build number is used so that a newer cbpy will be re-installed into the
# install/lib/python/runtime directory, and the MacOS wrapper script will
# install cbpy into a differently-named directory in the user's home dir.
SET (CBPY_VERSION 7.0.0)
SET (CBPY_BLD_NUM 1)

STRING (REGEX REPLACE "-.*" "" CB_VERSION "${PRODUCT_VERSION}")

SET (CBPY_BLD_NUM 5 CACHE INTERNAL "")

# Set up various paths and locations for Python-related things:

# Base directory for cbpy install - used by out-of-build programs such
# as the non-installed wrapper scripts created by PyWrapper(). Note that
# this directory is actually created by the local-cbpy target below.
SET (CBPY_PATH lib/python/runtime)
SET (CBPY_INSTALL "${CMAKE_INSTALL_PREFIX}/${CBPY_PATH}" CACHE INTERNAL "")
SET (CBPY_VER_FILE "${CBPY_INSTALL}/couchbase-${CB_VERSION}-py${CBPY_BLD_NUM}.version")

# Path to python interpreter in the local cbpy install.
IF (WIN32)
  SET (_localpy "${CBPY_INSTALL}/python.exe")
ELSE ()
  SET (_localpy "${CBPY_INSTALL}/bin/python3")
ENDIF ()
SET (PYTHON_EXE "${_localpy}" CACHE INTERNAL "Path to python interpreter")

# Path to the cbdeps-downloaded cbpy installer itself.
SET (_installer "${CMAKE_BINARY_DIR}/tlm/deps/cbpy.exploded/cbpy-installer")
IF (WIN32)
  SET (_installer "${_installer}.exe")
ELSE ()
  SET (_installer "${_installer}.sh")
ENDIF()

# Ship cbpy-installer with the Server installer
INSTALL (FILES "${_installer}" DESTINATION lib/python)

# Add the PyWrapper-related CMake functions.
INCLUDE (PyWrapperFunctions.cmake)

# Target to create local installation of our cbpy in the install directory.
# This is used by local scripts such as those created by PyWrapper() (defined
# in PyWrapperFunctions.cmake).
IF (WIN32)
  FILE (TO_NATIVE_PATH "${_installer}" _wininstaller)
  FILE (TO_NATIVE_PATH "${CBPY_INSTALL}" _wincbpy)
  ADD_CUSTOM_COMMAND (OUTPUT "${CBPY_VER_FILE}"
    COMMENT "Installing local cbpy"
    COMMAND rmdir /s /q "${_wincbpy}"
    COMMAND cmd /c start /wait
      "${_wininstaller}" /NoRegistry=1 /S "/D=${_wincbpy}"
    COMMAND "${CMAKE_COMMAND}" -E touch "${CBPY_VER_FILE}"
    VERBATIM)
ELSE ()
  ADD_CUSTOM_COMMAND (OUTPUT "${CBPY_VER_FILE}"
    COMMENT "Installing local cbpy"
    COMMAND rm -rf "${CBPY_INSTALL}"
    COMMAND "${_installer}" -b -p "${CBPY_INSTALL}"
    COMMAND "${CMAKE_COMMAND}" -E touch "${CBPY_VER_FILE}"
    VERBATIM)
ENDIF()

ADD_CUSTOM_TARGET (local-cbpy ALL DEPENDS "${CBPY_VER_FILE}")

# Clean targets

ADD_CUSTOM_TARGET ("local-cbpy-clean"
  COMMAND "${CMAKE_COMMAND}" -E remove_directory "${CBPY_INSTALL}"
  VERBATIM)

ADD_DEPENDENCIES (realclean local-cbpy-clean)
