@echo on

set INSTALL_DIR=%1
set PLATFORM=%2
set VERSION=%3

mkdir tmp
cd tmp
cmake -E tar xf ..\apache-maven-%VERSION%-bin.tar.gz
cd apache-maven-%VERSION%

rem Need to remove Unix shell scripts and copy Windows cmd scripts
rem to the Unix script names
del bin\mvn
copy bin\mvn.cmd bin\mvn
del bin\mvnDebug
copy bin\mvnDebug.cmd bin\mvnDebug

xcopy /I bin %INSTALL_DIR%\bin
xcopy /I boot %INSTALL_DIR%\boot
xcopy /I conf %INSTALL_DIR%\conf
xcopy /I lib %INSTALL_DIR%\lib
