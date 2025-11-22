#
#     Copyright 2021 Couchbase, Inc.
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

# Locate fmt library from cbdeps.
set(fmt_ROOT ${CMAKE_BINARY_DIR}/tlm/deps/fmt.exploded)

find_package(fmt REQUIRED)
if(fmt_FOUND)
    message(STATUS "Found fmt at: ${fmt_DIR}")
    # Need to treat this target as a non-system target. Otherwise, on
    # macOS, the include directory will be passed to the compiler with
    # -isystem instead of -I, which causes it to be searched after
    # /usr/local/include. `brew install ccache` causes `fmt` to be
    # installed into /usr/local, so those include files will break the
    # Server build.
    set_target_properties(fmt::fmt PROPERTIES SYSTEM FALSE)
endif()
