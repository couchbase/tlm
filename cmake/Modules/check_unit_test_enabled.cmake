#
#   Copyright 2018 Couchbase, Inc.
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

# Define a function (if not already defined) which checks if the given
# module name exists in the list of modules to disable building unit
# tests for.
#
# The list of modules must be specified in a cmake variable named
# COUCHBASE_DISABLED_UNIT_TESTS, and if not defined it'll fall back
# and look for an environment variable with the same name. The format
# of the value is "module1;module2;module3"
#
if (NOT COMMAND check_unit_test_enabled)
    # The function accepts two arguments:
    #   MODULE - The name to search for (eg. kv_engine)
    #   VARIABLE - The variable to set to true (if the test is to be run
    #              false otherwise)
    function(check_unit_test_enabled MODULE VARIABLE)
        set(_check_unit_test_enabled_mode True)

        if (NOT DEFINED COUCHBASE_DISABLED_UNIT_TESTS)
            if (DEFINED ENV{COUCHBASE_DISABLED_UNIT_TESTS})
                set(COUCHBASE_DISABLED_UNIT_TESTS $ENV{COUCHBASE_DISABLED_UNIT_TESTS} CACHE STRING "List of modules to disable unit tests for" FORCE)
            else ()
                set(COUCHBASE_DISABLED_UNIT_TESTS False CACHE BOOL "No list of modules to disable" FORCE)
            endif ()
        endif ()

        if (COUCHBASE_DISABLED_UNIT_TESTS)
            list(FIND COUCHBASE_DISABLED_UNIT_TESTS ${MODULE} _check_unit_test_enabled_index)
            if (${_check_unit_test_enabled_index} GREATER -1)
                message(WARNING "Skipping unit tests for ${MODULE}")
                set(_check_unit_test_enabled_mode False)
            endif ()
        endif ()
        set(${VARIABLE} ${_check_unit_test_enabled_mode} CACHE BOOL "Unit test for ${MODULE} is enabled" FORCE)
    endfunction()
endif (NOT COMMAND check_unit_test_enabled)
