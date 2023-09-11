# Select the compiler to use by default, if not specified by user.
# Sets CMAKE_C_COMPILER and CMAKE_CXX_COMPILER - note this file should
# be include()'d before the project() command as CMAKE_C_COMPILER
# cannot be changed after project().

# Use gcc from an alternate location if available (and the user didn't
# ask for something else using the standard CMAKE_C/CXX_COMPILER
# variables or CC / CXX env vars).
set (CB_GCC_PATH /opt/gcc-13.2.0 CACHE PATH "Preferred location for GCC, if available")
if(NOT DEFINED CMAKE_C_COMPILER AND
   NOT DEFINED CMAKE_CXX_COMPILER AND
   NOT DEFINED ENV{CC} AND
   NOT DEFINED ENV{CXX})
  if(EXISTS "${CB_GCC_PATH}")
    set(CMAKE_C_COMPILER "${CB_GCC_PATH}/bin/gcc" CACHE PATH "Path to C Compiler" FORCE)
    set(CMAKE_CXX_COMPILER "${CB_GCC_PATH}/bin/g++" CACHE PATH "Path to C++ Compiler" FORCE)
  endif()
endif()
