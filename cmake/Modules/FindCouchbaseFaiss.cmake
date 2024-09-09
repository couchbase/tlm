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

# Locate the Faiss library. This module utilizes the Faiss cbdeps
# package's CMake config, and so it defines "Modern CMake" imported
# targets named eg. "faiss" and "faiss_c". As such, there is no need for
# things like FAISS_LIBRARIES etc.
#
# We set the flag CB_USE_FAISS, which will be OFF on for non-Enterprise
# builds.

SET (_use_faiss OFF)
IF (NOT BUILD_ENTERPRISE)
  # No Faiss for CE builds

ELSEIF (BUILD_ONLY_TOOLS)
  # No Faiss for tools-only builds

ELSE ()
  SET (_use_faiss ON)
  FIND_PACKAGE (faiss CONFIG REQUIRED)
  MESSAGE (STATUS "Found faiss")

  # Add faiss's transitive dependencies to the install set
  IF (TARGET faiss_avx2)
    SET (_faisslib faiss_avx2)
  ELSEIF (TARGET faiss)
    SET (_faisslib faiss)
  ELSE ()
    MESSAGE (FATAL_ERROR "faiss package doesn't declare `faiss` or `faiss_avx2` target!")
  ENDIF ()
  INSTALL (IMPORTED_RUNTIME_ARTIFACTS faiss_c ${_faisslib})

  # On Mac and Windows, our Faiss package also includes the OpenMP runtime.
  # I couldn't find a useful way for Faiss's CMake config to include this,
  # so just manually install it here.
  IF (WIN32)
    INSTALL (FILES "${faiss_ROOT}/bin/libomp140.x86_64.dll" DESTINATION bin)
  ELSEIF (APPLE)
    INSTALL (FILES "${faiss_ROOT}/lib/libomp.dylib" DESTINATION lib)
  ENDIF ()
ENDIF ()

SET (CB_USE_FAISS ${_use_faiss} CACHE BOOL "Whether Faiss is available in the build" FORCE)
