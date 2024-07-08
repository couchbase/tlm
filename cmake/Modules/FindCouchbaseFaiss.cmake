#
#     Copyright 2024-present Couchbase, Inc.
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

# Locate the Faiss library This module utilizes the Faiss cbdeps
# package's CMake config, and so it defines "Modern CMake" imported
# targets named "faiss" and "faiss_c". As such, there is no need for
#  things like FAISS_LIBRARIES etc.
#
# For now we still have a CB_USE_FAISS flag, which will be OFF on
# Windows as well as for non-Enterprise builds.

SET (_use_faiss OFF)
IF (NOT BUILD_ENTERPRISE)
  # No Faiss for CE builds

ELSEIF (BUILD_ONLY_TOOLS)
  # No Faiss for tools-only builds

ELSEIF (WIN32)
  # Disabling vector search on Windows for 7.6.2

ELSE ()
  SET (_use_faiss ON)
  FIND_PACKAGE (faiss CONFIG REQUIRED)
  MESSAGE (STATUS "Found faiss")

  # Add faiss's transitive dependencies to the install set
  INSTALL (IMPORTED_RUNTIME_ARTIFACTS faiss faiss_c)
ENDIF ()

SET (CB_USE_FAISS ${_use_faiss} CACHE BOOL "Whether Faiss is available in the build" FORCE)
