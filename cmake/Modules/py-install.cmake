MACRO (exec COMMAND)
  EXECUTE_PROCESS (
    COMMAND "${COMMAND}" ${ARGN}
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _output
    ERROR_VARIABLE _output
  )
  IF (_result)
    MESSAGE (FATAL_ERROR "Error running ${COMMAND} ${ARGN}!\n${_output}")
  ENDIF ()
ENDMACRO (exec)

MACRO (python)
  exec ("${PYTHON_EXE}" ${ARGN})
ENDMACRO (python)

# Set VIRTUAL_ENV the way activating a venv does.
SET (ENV{VIRTUAL_ENV} "${VENV_DIR}")
IF (WIN32)
  SET (PYTHON_EXE "${VENV_DIR}/Scripts/python.exe")
ELSE ()
  SET (PYTHON_EXE "${VENV_DIR}/bin/python")
ENDIF ()

# Compute script directory and corresponding binary directory
GET_FILENAME_COMPONENT (SCRIPT_DIR "${SCRIPTFILE}" DIRECTORY)
GET_FILENAME_COMPONENT (BINARY_DIR "${BUILD_DIR}" DIRECTORY)

# Add hidden import paths
FOREACH (IMPORT ${HIDDENIMPORTS})
  LIST (APPEND _pyimports --hidden-import ${IMPORT})
ENDFOREACH ()

# Add extra binaries
FOREACH (BINARY ${EXTRA_BIN})
  LIST (APPEND _extrabin --add-binary ${BINARY}:.)
ENDFOREACH ()

# Export LD_LIBRARY_PATH / DYLD_LIBRARY_PATH / PATH so PyInstaller can
# find all dependent libraries
IF (WIN32)
  LIST (APPEND ENV{PATH} "${LIBRARY_DIRS}")
ELSE ()
  STRING (REPLACE ";" ":" _libs "${LIBRARY_DIRS}")
  IF (APPLE)
    SET (ENV{DYLD_LIBRARY_PATH} "${_libs}")
  ELSE ()
    SET (ENV{LD_LIBRARY_PATH} "${_libs}")
  ENDIF ()
ENDIF ()

# Tell PyInstaller to use a different cache dir for each build as well
SET (ENV{PYINSTALLER_CONFIG_DIR} "${BUILD_DIR}/cache")

# Run PyInstaller to produce output into lib/ directory
python (-m PyInstaller
  --log-level INFO
  --workpath ${BUILD_DIR}
  --specpath ${BUILD_DIR}
  --distpath ${BUILD_DIR}/lib
  --paths ${SCRIPT_DIR}
  --paths ${BINARY_DIR}
  ${_pyimports}
  ${_extrabin}
  --name "${NAME}"
  --onedir --noconfirm
  ${SCRIPTFILE})

# Create local symlink if requested
IF (NOT WIN32)
  IF (SYMLINK_DIR)
    exec ("${CMAKE_COMMAND}"
      -E create_symlink
      "${BUILD_DIR}/lib/${NAME}/${NAME}"
      "${SYMLINK_DIR}/${NAME}")
  ENDIF ()
ENDIF ()