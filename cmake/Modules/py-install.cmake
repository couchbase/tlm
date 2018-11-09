# Ensure pipenv creates a new virtualenv for this work
SET (ENV{PIPENV_IGNORE_VIRTUALENVS} 1)

MACRO (pipenv)
  EXECUTE_PROCESS (RESULT_VARIABLE _result
    COMMAND "${PYTHON_PIPENV}" ${ARGN}
  )
  IF (_result)
    MESSAGE (FATAL_ERROR "Error running pipenv ${ARGN}!")
  ENDIF ()
ENDMACRO (pipenv)

# Install pre-requisites using only Pipfile.lock
pipenv (install --ignore-pipfile)

# Install PyInstaller (DON'T use "pipenv install" so it doesn't modify
# the source code Pipfile!)
pipenv (run pip install pyinstaller)

# Run PyInstaller to produce output binary
pipenv (run pyinstaller
  --log-level INFO
  --workpath ${BUILD_DIR}
  --specpath ${BUILD_DIR}
  --distpath ${BUILD_DIR}/..
  --name ${OUTPUT}
  --onefile
  ${SCRIPTFILE})