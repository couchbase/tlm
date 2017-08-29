@echo on

set INSTALL_DIR=%1

set PYTHON=C:\Python27\python.exe
call .\vcbuild.bat release shared
if errorlevel 1 exit /b 1

@echo on
mkdir %INSTALL_DIR%\lib
copy .\Release\libuv.* %INSTALL_DIR%\lib
mkdir %INSTALL_DIR%\include
copy .\include\*.h %INSTALL_DIR%\include\*.h
