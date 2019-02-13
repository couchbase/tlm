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

# Set the compiler flags for Clang C and C++ compilator
include(CheckCXXCompilerFlag)

# Add common flags for C and C++
foreach (dir ${CB_SYSTEM_HEADER_DIRS})
    list(APPEND _cb_c_flags "-isystem ${dir}")
endforeach (dir ${CB_SYSTEM_HEADER_DIRS})

if (CB_CODE_COVERAGE)
    list(APPEND _cb_c_flags
         --coverage
         -fprofile-instr-generate
         -fcoverage-mapping)
    set(CMAKE_LINK_FLAGS "${CMAKE_LINK_FLAGS} -fprofile-instr-generate")
endif ()

list(APPEND _cb_c_flags -fvisibility=hidden -pthread)
if (CMAKE_GENERATOR STREQUAL "Ninja")
    # Enable color diagnostic output when using Ninja build generator
    # (Clang fails to auto-detect it can use color).
    list(APPEND _cb_c_flags -fcolor-diagnostics)
endif ()

# Copy the flags over to C++
set(_cb_cxx_flags ${_cb_c_flags})

# Configure the C compiler
list(APPEND _cb_c_flags
     --std=gnu99
     -Qunused-arguments
     -Wall
     -pedantic
     -Werror=missing-prototypes
     -Werror=missing-declarations
     -Werror=redundant-decls
     -fno-strict-aliasing
     -Wno-overlength-strings)

# Convert the list to a string
string(REPLACE ";" " " _cb_c_options "${_cb_c_flags}")

# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
set(CMAKE_C_FLAGS_RELEASE        "-O3 -DNDEBUG")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "-O3 -DNDEBUG -g")
set(CMAKE_C_FLAGS_DEBUG          "-O0 -g")
set(CB_CXX_FLAGS_NO_OPTIMIZE     "-O0")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${_cb_c_options}")

# Configure the C++ compiler
#   (Ideally we shouldn't be setting -std=c++14 here as we try to use
#   set(CMAKE_CXX_STANDARD 14), but the option isn't added to the
#   check_cxx_source_compiles causing such tests to fail.
#   Keep the flag here until we've safely removed all of these
#   checks)
list(APPEND _cb_cxx_flags
     -Qunused-arguments
     -Wall
     -pedantic
     -fno-strict-aliasing
     -Werror=switch
     -Werror=redundant-decls
     -Werror=missing-braces
     -ftemplate-depth=900)

# https://bugs.llvm.org/show_bug.cgi?id=31815: Clang issues spurious
# Wunused-lambda-capture warnings. Disable this warning until the fix is
# picked up in the versions of clang we use.
check_cxx_compiler_flag(-Wno-unused-lambda-capture HAVE_NO_UNUSED_LAMBDA_CAPTURE)
if (HAVE_NO_UNUSED_LAMBDA_CAPTURE)
  list(APPEND _cb_cxx_flags -Wno-unused-lambda-capture)
endif()

# Convert the list to a string
string(REPLACE ";" " " _cb_cxx_options "${_cb_cxx_flags}")

# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O3 -DNDEBUG -g")

# Make use of -Og (optimize for debugging) if available (Clang 4.0 upwards)
check_cxx_compiler_flag(-Og HAVE_OPTIMIZE_FOR_DEBUG)
if (HAVE_OPTIMIZE_FOR_DEBUG)
    set(CMAKE_CXX_FLAGS_DEBUG "-Og -g")
else ()
    set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g")
endif ()
set(CB_CXX_FLAGS_NO_OPTIMIZE -O0)

set(CB_GNU_CXX11_OPTION "-std=gnu++11")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_cb_cxx_options}")
