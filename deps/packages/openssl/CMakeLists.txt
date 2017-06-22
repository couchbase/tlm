# Downloads the declared version of OpenSSL source code and builds it.

IF (APPLE)
  INCLUDE ("openssl_macosx.cmake")
ELSEIF (WIN32)
  INCLUDE ("openssl_windows.cmake")
ENDIF()

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
