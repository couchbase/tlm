# A stubbed "external" project, because the cbpy build instructions
# are actually right here.

# This is the Master Version of Python to use everywhere!
SET (PYTHON_VERSION 3.9.16)

# These are tool versions, shouldn't need changing often
SET (CBDEP_VERSION 1.1.1)
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
FILE (TO_NATIVE_PATH "${_install_dir}" _install_native_dir)
FILE (TO_NATIVE_PATH "${CMAKE_CURRENT_SOURCE_DIR}" _source_native_dir)

# We abuse the DOWNLOAD step here to grab cbdep for us. cbdep knows the
# vagaries of downloading and installing a local Miniforge to kickstart
# the whole process.
# Other notes:
#  - We do not specify BUILD_IN_SOURCE 1, so the script can assume that cwd
#    is where it should dump stuff
#  - We pass CMAKE_CURRENT_SOURCE_DIR to the script so it knows where to
#    find conda-pkgs etc.
# Also, we set BINARY_DIR (which is where the CWD will be when the real build
# script is invoked) to a specific short relative path, because conda gets
# buggy if environment paths are longer than 127 characters long.
ExternalProject_Add(cbpy
  URL "${_cbdep_url_base}${_cbdep_url_ext}"
  DOWNLOAD_NO_EXTRACT true
  CONFIGURE_COMMAND ""
  BINARY_DIR build
  BUILD_COMMAND "${_build_script}" "${_source_native_dir}" <DOWNLOADED_FILE> ${MINIFORGE_VERSION} ${PYTHON_VERSION} "${_install_native_dir}"
  INSTALL_DIR "${_install_dir}"
  INSTALL_COMMAND ""
)

# cbdeps boilerplate
_ADD_PACKAGE_STEP()
