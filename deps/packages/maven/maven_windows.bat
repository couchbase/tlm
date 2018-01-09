@echo on

set INSTALL_DIR=%1
set PLATFORM=%2
set VERSION=%3

mkdir tmp
cd tmp
cmake -E tar xf ..\apache-maven-%VERSION%-bin.tar.gz
cd apache-maven-%VERSION%

xcopy /I /E bin %INSTALL_DIR%\bin
xcopy /I /E boot %INSTALL_DIR%\boot
xcopy /I /E conf %INSTALL_DIR%\conf
xcopy /I /E lib %INSTALL_DIR%\lib
