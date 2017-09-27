@echo on

set INSTALL_DIR=%1

mkdir tmp
cd tmp
cmake -E tar xf ..\flex-2.5.4a-1-bin.zip
xcopy /I bin %INSTALL_DIR%\bin
