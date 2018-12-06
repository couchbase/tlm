MACRO (exec COMMAND)
  EXECUTE_PROCESS (RESULT_VARIABLE _result
    COMMAND "${COMMAND}" ${ARGN}
  )
  IF (_result)
    MESSAGE (FATAL_ERROR "Error running ${COMMAND} ${ARGN}!")
  ENDIF ()
ENDMACRO (exec)

MACRO (python)
  exec ("${PYTHON_EXE}" ${ARGN})
ENDMACRO (python)

# Set VIRTUAL_ENV the way activating a venv does.
SET (ENV{VIRTUAL_ENV} "${VENV_DIR}")
SET (PYTHON_EXE "${VENV_DIR}/bin/python")

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
MESSAGE (STATUS "Hidden imports is ${_pyimports}; extra bins is ${_extrabin}")

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
    MESSAGE (STATUS "ldlibpath $ENV{LD_LIBRARY_PATH}")
  ENDIF ()
ENDIF ()

# Run PyInstaller to produce output binary
python (-m PyInstaller
  --log-level INFO
  --workpath ${BUILD_DIR}
  --specpath ${BUILD_DIR}
  --distpath ${BUILD_DIR}/..
  --paths ${SCRIPT_DIR}
  --paths ${BINARY_DIR}
  ${_pyimports}
  ${_extrabin}
  --name ${OUTPUT}
  --onefile
  ${SCRIPTFILE})
