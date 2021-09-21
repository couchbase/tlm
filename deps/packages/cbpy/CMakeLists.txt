# A stubbed "external" project, because the cbpy build instructions
# are actually right here.

SET (CBDEP_VERSION 1.0.4)
SET (MINIFORGE_VERSION 4.10.3-5)

include(ExternalProject)

SET (_cbdep_url_base "https://packages.couchbase.com/cbdep/${CBDEP_VERSION}/cbdep-${CBDEP_VERSION}-")

IF (WIN32)
  SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/cbpy_windows.bat)
  SET (_cbdep_url_ext "windows.exe")
ELSE ()
  IF(APPLE)
    SET (_cbdep_platform "darwin")
    SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/cbpy_unix.sh)
  ELSE ()
    SET (_cbdep_platform "linux")
    SET (_build_script ${CMAKE_CURRENT_SOURCE_DIR}/cbpy_unix.sh)
  ENDIF ()
  STRING (TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" _arch)
  SET (_cbdep_url_ext "${_cbdep_platform}-${_arch}")
ENDIF ()

SET (_install_dir "${CMAKE_BINARY_DIR}/install")
FILE (TO_NATIVE_PATH "${_install_dir}" _install_dir)

# We abuse the DOWNLOAD step here to grab cbdep for us. cbdep knows the
# vagaries of downloading and installing a local Miniforge to kickstart
# the whole process.
# Other notes:
#  - We do not specify BUILD_IN_SOURCE 1, so the script can assume that cwd
#    is where it should dump stuff
#  - We pass CMAKE_CURRENT_SOURCE_DIR to the script so it knows where to
#    find conda-pkgs etc.
ExternalProject_Add(cbpy
  URL "${_cbdep_url_base}${_cbdep_url_ext}"
  DOWNLOAD_NO_EXTRACT true
  CONFIGURE_COMMAND ""
  BUILD_COMMAND "${_build_script}" "${CMAKE_CURRENT_SOURCE_DIR}" <DOWNLOADED_FILE> ${MINIFORGE_VERSION} <INSTALL_DIR>
  INSTALL_DIR "${_install_dir}"
  INSTALL_COMMAND ""
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
