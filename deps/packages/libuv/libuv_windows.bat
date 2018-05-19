@echo on

set INSTALL_DIR=%1

set PYTHON=C:\Python27\python.exe
set GYP_MSVS_VERSION=2015
call .\vcbuild.bat release shared x64
if errorlevel 1 exit /b 1

@echo on
mkdir %INSTALL_DIR%\lib
mkdir %INSTALL_DIR%\bin
copy .\Release\libuv.* %INSTALL_DIR%\lib
move %INSTALL_DIR%\lib\libuv.dll %INSTALL_DIR%\bin
mkdir %INSTALL_DIR%\include
copy .\include\*.h %INSTALL_DIR%\include\*.h
