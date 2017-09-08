@echo on

set INSTALL_DIR=%1

cd win_binary
mkdir tmp
cd tmp
cmake -E tar xf ..\icu4c-59_1-Win64-MSVC2015.zip

xcopy /I bin64 %INSTALL_DIR%\bin
xcopy /I lib64 %INSTALL_DIR%\lib
xcopy /I /E include %INSTALL_DIR%\include
