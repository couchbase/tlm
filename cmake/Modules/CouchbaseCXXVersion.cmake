MESSAGE(STATUS "C++ compiler version: ${CMAKE_CXX_COMPILER_VERSION}")
MESSAGE(STATUS "C++ language version: ${CB_CXX_LANG_VER}")

IF (NOT COMPILER_SUPPORTS_CXX11)
  MESSAGE("The C++ compiler (${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}) is too old and don't support C++11.
C++11 support is required for Sherlock - please upgrade your compiler. See the following links for information on some common platforms:
- Ubuntu 12.04: http://goo.gl/HMOfwv (suggest g++ 4.9+)
- CentOS 6: http://goo.gl/yaz0xb (suggest c++ 4.8+)")
  MESSAGE(FATAL_ERROR "A compiler supporting C++11 is required to build.")
ENDIF()

