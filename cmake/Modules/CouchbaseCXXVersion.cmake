MESSAGE(STATUS "C++ compiler version: ${CMAKE_CXX_COMPILER_VERSION}")
MESSAGE(STATUS "C++ language version: ${CB_CXX_LANG_VER}")

IF (NOT COMPILER_SUPPORTS_CXX11)
  MESSAGE(WARNING "*****************************************************************************
The C++ compiler (${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}) is too old and don't support C++11.
C++11 support will be required for Sherlock. Support for pre C++11 compilers will be *dropped* in the next few weeks. Please upgrade your compiler to continue being able to build. See the following links for information on some common platforms:
- Ubuntu 12.04: http://goo.gl/HMOfwv (suggest g++ 4.9+)
- CentOS 6: http://goo.gl/yaz0xb (suggest c++ 4.8+)
*****************************************************************************
(sleeping for 10 seconds...)
")
  EXECUTE_PROCESS(COMMAND sleep 10)
ENDIF()

