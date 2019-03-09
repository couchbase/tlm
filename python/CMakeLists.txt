INCLUDE (FindCouchbasePython)
INCLUDE (CBDownloadDeps)

# Target to download and install stock Miniconda3. This python
# installation is used ONLY to install Constructor, which is then
# used to build our bespoke cbpy installer.

SET (MINICONDA_VERSION 4.5.4)
SET (_miniconda_install "${CMAKE_CURRENT_BINARY_DIR}/miniconda3-${MINICONDA_VERSION}")
IF (WIN32)
  SET (_pyexe "${_miniconda_install}/python.exe")
  SET (_condaexe "${_miniconda_install}/Scripts/conda.exe")
ELSE ()
  SET (_pyexe "${_miniconda_install}/bin/python")
  SET (_condaexe "${_miniconda_install}/bin/conda")
ENDIF ()
SET (CONDA_EXE "${_condaexe}" CACHE INTERNAL "Path to conda program")

ADD_CUSTOM_COMMAND (OUTPUT "${CONDA_EXE}"
  COMMENT "Creating Miniconda3 ${MINICONDA_VERSION} install"
  COMMAND "${CMAKE_COMMAND}" -E remove_directory "${_miniconda_install}"
  COMMAND "${CBDEP}" install -d "${CMAKE_CURRENT_BINARY_DIR}"
      miniconda3 ${MINICONDA_VERSION}
  VERBATIM)

ADD_CUSTOM_TARGET(miniconda3 ALL DEPENDS "${CONDA_EXE}")

# Target to add constructor to the global Miniconda installation

GET_FILENAME_COMPONENT (_pydir "${CONDA_EXE}" DIRECTORY)
SET (_constructor "${_pydir}/constructor")
IF (WIN32)
  SET (_constructor "${_constructor}.exe")
ENDIF ()

# Invoke conda to install constructor. Note: on Docker swarm slaves, the
# build environment is launched via sudo. This breaks conda for dumb
# reasons (https://github.com/conda/conda/issues/7267). Workaround is
# to unset SUDO_UID when invoking.
ADD_CUSTOM_COMMAND (OUTPUT "${_constructor}"
  COMMENT "Installing Anaconda Constructor"
  DEPENDS miniconda3
  COMMAND "${CMAKE_COMMAND}" -E env --unset=SUDO_UID
    "${CONDA_EXE}" install -y constructor
  VERBATIM)

# Target to create our "microconda" installer
SET (_installer "${CMAKE_CURRENT_BINARY_DIR}/cbpy-installer")
IF (WIN32)
  SET (_installer "${_installer}.exe")
ELSE ()
  SET (_installer "${_installer}.sh")
ENDIF ()

ADD_CUSTOM_COMMAND (OUTPUT "${_installer}"
  COMMAND "${_constructor}" "${CMAKE_CURRENT_SOURCE_DIR}"
  COMMAND "${CMAKE_COMMAND}" -E rename cbpy-installer "${_installer}"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/construct.yaml" "${_constructor}"
  COMMENT "Build cbpy distribution"
  VERBATIM)

ADD_CUSTOM_TARGET (cbpy-installer ALL DEPENDS "${_installer}")
INSTALL (FILES "${_installer}" DESTINATION lib/python)

# Target to create local installation of our "microconda"
# in the install directory

IF (WIN32)
  FILE (TO_NATIVE_PATH "${_installer}" _wininstaller)
  FILE (TO_NATIVE_PATH "${CBPY_INSTALL}" _wincbpy)
  ADD_CUSTOM_COMMAND (OUTPUT "${PYTHON_EXE}"
    COMMENT "Installing local cbpy"
    DEPENDS cbpy-installer
    COMMAND cmd /c start /wait
      "${_wininstaller}" /NoRegistry=1 /S "/D=${_wincbpy}"
      VERBATIM)
ELSE ()
  ADD_CUSTOM_COMMAND (OUTPUT "${PYTHON_EXE}"
    COMMENT "Installing local cbpy"
    DEPENDS cbpy-installer
    COMMAND "${_installer}" -b -p "${CBPY_INSTALL}"
    VERBATIM)
ENDIF()

ADD_CUSTOM_TARGET (local-cbpy ALL DEPENDS "${PYTHON_EXE}")

# Clean targets

ADD_CUSTOM_TARGET ("miniconda3-clean"
  COMMAND "${CMAKE_COMMAND}" -E remove_recurse "${_miniconda_install}"
  VERBATIM)

ADD_CUSTOM_TARGET ("cbpy-installer-clean"
  COMMAND "${CMAKE_COMMAND}" -E remove "${_installer}"
  VERBATIM)

ADD_CUSTOM_TARGET ("local-cbpy-clean"
  COMMAND "${CMAKE_COMMAND}" -E remove_recurse "${CBPY_INSTALL}"
  VERBATIM)

ADD_DEPENDENCIES (realclean miniconda3-clean cbpy-installer-clean local-cbpy-clean)
