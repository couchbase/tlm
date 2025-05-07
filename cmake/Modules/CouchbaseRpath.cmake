SET(CMAKE_SKIP_BUILD_RPATH FALSE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

# If the system supports it we want to add in $ORIGIN
IF (UNIX)
  IF(APPLE)
    SET (ORIGIN @executable_path)
  ELSE(APPLE)
    SET (ORIGIN \$ORIGIN)
  ENDIF(APPLE)
  SET(RPATH ${ORIGIN}/../lib)
ENDIF()

SET(RPATH "${RPATH};${CMAKE_INSTALL_PREFIX}/lib")
IF ("${CMAKE_INSTALL_RPATH}" STREQUAL "")
ELSE()
  SET(RPATH "${RPATH};${CMAKE_INSTALL_RPATH}")
ENDIF()
SET(CMAKE_INSTALL_RPATH "${RPATH}")

SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# Remove any rpath added by the toolchain. This is necessary to remove
# the local '/opt/gcc-10.2.0/lib64' rpath added by our local gcc-10
# binary to allow the binary to locate libstdc++ et al at build
# time. At install time we locate libstdc++ via the above
# origin-relative path.
SET(CMAKE_INSTALL_REMOVE_ENVIRONMENT_RPATH TRUE)

# Make the `StripGccRpath` function available for other `INSTALL(CODE)`
# calls.
INSTALL(SCRIPT "${CMAKE_CURRENT_LIST_DIR}/cb_strip_gcc_rpath.cmake" ALL_COMPONENTS)
