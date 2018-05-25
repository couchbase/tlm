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

# Locate and configure Valgrind for memory checking.
# This module defines
#    MEMORYCHECK_COMMAND - containing the path to valgrind
#    MEMORYCHECK_COMMAND_OPTIONS - The options to pass to valgrind
if (NOT DEFINED MEMORYCHECK_COMMAND)
    find_program(MEMORYCHECK_COMMAND valgrind)
    set(_valgrind_options
        "--gen-suppressions=all"
        "--leak-check=full"
        "--num-callers=32"
        "--partial-loads-ok=yes"
        "--show-leak-kinds=all"
        # MB-26684: New features we introduced in RocksDBKVStore
        # led to the execution of the 'malloc_usable_size' function.
        # While the 'new' and  'delete' operators in 'libstd++' are
        # correctly redirected to the Valgrind ones, we need to tell
        # Valgrind to redirect also the 'malloc_usable_size' function in
        # 'libplatform'. Missing that leads to SegFault when the
        # non-Valgrind 'malloc_usable_size' is called giving in input a
        # pointer to a Valgrind-allocated block of memory.
        "--soname-synonyms=somalloc=libplatform_so.*"
        "--suppressions=${CMAKE_SOURCE_DIR}/tlm/valgrind.supp"
        "--trace-children=yes"
        "--track-origins=yes"
        "--xml=yes --xml-file=memcheck.%p.xml")

    string(REPLACE ";" " " MEMORYCHECK_COMMAND_OPTIONS "${_valgrind_options}")
endif (NOT DEFINED MEMORYCHECK_COMMAND)
