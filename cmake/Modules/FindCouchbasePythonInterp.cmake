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

# Locate Python and check if it may be used to run the couchbase tests
#
# This module defines
#  COUCHBASE_PYTHON, Set to true if we may use this version of python

if (NOT DEFINED COUCHBASE_PYTHON)
    include(FindPythonInterp)

    if (NOT DEFINED PYTHON_VERSION_MAJOR)
        set(PYTHON_VERSION_MAJOR "0")
    endif ()

    if (NOT DEFINED PYTHON_VERSION_MINOR)
        set(PYTHON_VERSION_MINOR "0")
    endif ()

    if (${PYTHON_VERSION_MAJOR} GREATER 2 OR ${PYTHON_VERSION_MINOR} GREATER 5)
        set(COUCHBASE_PYTHON true CACHE BOOL "Found new enough Python" FORCE)
    else ()
        set(COUCHBASE_PYTHON false CACHE BOOL "Python is too old for us to use" FORCE)
        message(WARNING "You should upgrade python so you can run tests!!!!!")
    endif ()
endif (NOT DEFINED COUCHBASE_PYTHON)
