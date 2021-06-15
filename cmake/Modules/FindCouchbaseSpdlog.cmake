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

# Locate https://github.com/gabime/spdlog library.

set(spdlog_ROOT ${CMAKE_BINARY_DIR}/tlm/deps/spdlog.exploded)
# When building with ThreadSanitizer, prepend its root dir so we pick up
# the TSan-enabled library ahead of the vanilla one.
if(CB_THREADSANITIZER)
    list(PREPEND spdlog_ROOT ${CMAKE_BINARY_DIR}/tlm/deps/spdlog.exploded/tsan_root)
endif()

find_package(spdlog REQUIRED)
if(spdlog_FOUND)
    message(STATUS "Found spdlog at: ${spdlog_DIR}")
endif()
