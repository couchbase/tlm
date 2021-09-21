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

# The version of cbpy, as extracted from tlm/deps/manifest.cmake.
SET (CBPY_VERSION "${CBDEP_cbpy_VERSION}")

# Set up various paths and locations for Python-related things:

# Base directory for cbpy install - used by out-of-build programs such
# as the non-installed wrapper scripts created by PyWrapper(). This must
# match the DESTINATION in tlm/deps/manifest.cmake for cbpy.
SET (CBPY_PATH lib/python/interp)
SET (CBPY_INSTALL "${CMAKE_INSTALL_PREFIX}/${CBPY_PATH}" CACHE INTERNAL "")

# Path to python interpreter in the install directory. Any build steps
# that want to run python scripts should use ${PYTHON_EXE}.
IF (WIN32)
  SET (_localpy "${CBPY_INSTALL}/python.exe")
ELSE ()
  SET (_localpy "${CBPY_INSTALL}/bin/python3")
ENDIF ()
SET (PYTHON_EXE "${_localpy}" CACHE INTERNAL "Path to python interpreter")

# Add the PyWrapper-related CMake functions.
INCLUDE (PyWrapperFunctions.cmake)

# Leaving this for historical purposes until other code
# can be updated.
ADD_CUSTOM_TARGET (local-cbpy ALL)
