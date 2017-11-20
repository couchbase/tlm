IF (WIN32)
  INCLUDE ("icu4c_windows.cmake")
ELSE ()
  INCLUDE ("icu4c_unix.cmake")
ENDIF()

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
