@echo off
rem This is a small script used to execute a set off commands in an
rem environment set up for the Microsoft Visual Studio toolchanin

setlocal

echo "query registry for: HKLM\Software\WOW6432Node\Microsoft\VisualStudio\SxS\VC7"
for /F "tokens=1,2*" %%i in ('reg query "HKLM\Software\WOW6432Node\Microsoft\VisualStudio\SxS\VC7"') DO (
   if "%%i"=="10.0" ( SET "FOUND_DIR=%%k"
                      goto FOUND_DIR
                    )
   if "%%i"=="11.0" ( SET "FOUND_DIR=%%k"
                      goto FOUND_DIR
                    )
)

echo "query registry for: HKLM\Software\WOE6432Node\Microsoft\VisualStudio\SxS\VC7"
for /F "tokens=1,2*" %%i in ('reg query "HKLM\Software\WOE6432Node\Microsoft\VisualStudio\SxS\VC7"') DO (
   if "%%i"=="10.0" ( SET "FOUND_DIR=%%k"
                      goto FOUND_DIR
                    )
   if "%%i"=="11.0" ( SET "FOUND_DIR=%%k"
                      goto FOUND_DIR
                    )
)

echo "query registry for: HKLM\Software\Microsoft\VisualStudio\SxS\VC7"
if "%FOUND_DIR%" == "" (
   for /F "tokens=1,2*" %%i in ('reg query "HKLM\Software\Microsoft\VisualStudio\SxS\VC7"') DO (
      if "%%i"=="10.0" ( SET "FOUND_DIR=%%k"
                         goto FOUND_DIR
                       )
      if "%%i"=="11.0" ( SET "FOUND_DIR=%%k"
                         goto FOUND_DIR
                       )
   )
)

if "%FOUND_DIR%" == "" (
  echo Visual Studio Not Found >&2
  set RC=255
  goto ll_done
)

:FOUND_DIR

echo "Using %FOUND_DIR%\bin\vcvars32.bat"
call "%FOUND_DIR%\bin\vcvars32.bat"
rem echo "Current environment: "
rem set

rem
rem We need to unset some of the make environments with incompatible
rem values.
rem

set MAKEFLAGS=
set MAKELEVEL=
set MAKEOVERRIDES=
SET PATH=C:\Program Files\CMake 2.8\bin;C:\Program Files (x86)\CMake 2.8\bin;%PATH%
@echo on
%*
set RC=%ERRORLEVEL%
@echo off

:ll_done
set ERRORLEVEL=%RC%
EXIT /B %ERRORLEVEL%
