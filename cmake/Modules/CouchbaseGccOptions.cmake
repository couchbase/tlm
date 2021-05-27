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

# Set the compiler flags for gcc and g++ compilator

# Add common flags for C and C++
foreach (dir ${CB_SYSTEM_HEADER_DIRS})
   list(APPEND _cb_c_flags "-isystem ${dir}")
endforeach (dir ${CB_SYSTEM_HEADER_DIRS})

if (CB_CODE_COVERAGE)
   list(APPEND _cb_c_flags --coverage)
   set(CMAKE_LINK_FLAGS "${CMAKE_LINK_FLAGS} --coverage")
endif ()

if (NOT COUCHBASE_OMIT_FRAME_POINTER)
   message(STATUS "Add -fno-omit-frame-pointer")
   list(APPEND _cb_c_flags -fno-omit-frame-pointer)
endif()

# If building with a version of GCC which defaults to PIE code
# (--enable-default-pie), we can encounter linker errors when linking
# against precompiled static libraries similar to:
#
#     /usr/bin/ld: foo.a(bar.cc.o): relocation R_X86_64_32 against `.rodata.str1.8' can not be used when making a PIE object; recompile with -fPIC
#
# Address this by disabling the effect of '--enable-default-pie' - set
# the default to non- position-independent executables.
#
include(CheckCCompilerFlag)
check_c_compiler_flag(-no-pie HAVE_NO_PIE)
if (HAVE_NO_PIE)
  list(APPEND CMAKE_EXE_LINKER_FLAGS "-no-pie")
endif ()

list(APPEND _cb_c_flags -fvisibility=hidden -pthread)
# Copy the flags over to C++
set(_cb_cxx_flags ${_cb_c_flags})

# Add C specific options
list(APPEND cb_c_flags
     -std=gnu99
     -Wall
     -pedantic
     -Werror=missing-prototypes
     -Werror=missing-declarations
     -Wredundant-decls
     -fno-strict-aliasing
     -Wno-overlength-strings)

# Convert the list to a string
string(REPLACE ";" " " _cb_c_options "${_cb_c_flags}")

# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
set(CMAKE_C_FLAGS_RELEASE        "-O3 -DNDEBUG")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "-O3 -DNDEBUG -g")
set(CMAKE_C_FLAGS_DEBUG          "-Og -g")
set(CB_C_FLAGS_NO_OPTIMIZE       "-O0")
set(CB_FLAGS_OPTIMIZE_FOR_DEBUG  ${CMAKE_C_FLAGS_DEBUG})
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${_cb_c_options}")

# Configure the C++ compiler
list(APPEND _cb_cxx_flags
     -pedantic
     -Wall
     -Wredundant-decls
     -Werror=missing-braces
     -fno-strict-aliasing
     -Werror=switch)

SET(CB_GNU_CXX11_OPTION "-std=gnu++17")

# Convert the list to a string
string(REPLACE ";" " " _cb_cxx_options "${_cb_cxx_flags}")

# We want RelWithDebInfo to have the same optimization level as
# Release, only differing in whether debugging information is enabled.
set(CMAKE_CXX_FLAGS_RELEASE        "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O3 -DNDEBUG -g")
set(CMAKE_CXX_FLAGS_DEBUG          "-g")
set(CB_CXX_FLAGS_NO_OPTIMIZE       "-O0")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_cb_cxx_options}")
