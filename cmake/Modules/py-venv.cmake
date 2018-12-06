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

MACRO (EXPORT_FLAGS var flag)
  IF (${var})
    SET (_value)
    FOREACH (_dir ${${var}})
      SET (_value "${_value} ${flag} ${_dir}")
    ENDFOREACH (_dir)
    SET (ENV{PIP_INSTALL_OPTION} "$ENV{PIP_INSTALL_OPTION} ${_value}")
  ENDIF (${var})
ENDMACRO (EXPORT_FLAGS)

# Create the virtual environment.
python (-m venv "${VENV_DIR}")

# Set VIRTUAL_ENV the way activating a venv does.
SET (ENV{VIRTUAL_ENV} "${VENV_DIR}")

# Use our "new" python
SET (PYTHON_EXE "${VENV_DIR}/bin/python")

# Touch 'created' file
FILE (TOUCH "${VENV_DIR}/created")

# Convert xxx_DIRS values into compiler-appropriate parameters
# in the envvar PIP_INSTALL_OPTION.
# https://stackoverflow.com/a/22942120/1425601
SET (ENV{PIP_INSTALL_OPTION} "build_ext")
EXPORT_FLAGS (INCLUDE_DIRS "-I")
EXPORT_FLAGS (LIBRARY_DIRS "-L")
MESSAGE (STATUS "PIP_INSTALL_OPTION: $ENV{PIP_INSTALL_OPTION}")

# Install pre-requisites using requirements.txt
python (-m pip install pyinstaller -r requirements.txt)
