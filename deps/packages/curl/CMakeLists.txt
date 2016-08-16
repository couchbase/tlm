# Downloads the declared version of libcurl source code and builds it.

IF (WIN32)
  INCLUDE ("curl_windows.cmake")
ELSE ()
  INCLUDE ("curl_unix.cmake")
ENDIF ()

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
