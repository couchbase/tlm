set INSTALL_DIR=%1
set DEPS=%WORKSPACE%\deps

set SITE=https://packages.couchbase.com/cbdep/cbdep-0.8.0-windows.exe
set FILENAME=%WORKSPACE%\cbdep.exe
powershell -command "& { (New-Object Net.WebClient).DownloadFile('%SITE%', '%FILENAME%') }" || goto error
%WORKSPACE%\cbdep.exe install -d "%DEPS%" golang 1.10.3

set GOPATH=%WORKSPACE%
set GOROOT=%DEPS%\go1.10.3
set PATH=%GOROOT%\bin;%PATH%

rem Build grpc binaries and libraries
call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat" x64
md .build
cd .build
cmake .. -G "NMake Makefiles" -DCMAKE_INSTALL_PREFIX="C:\cb2\install"
cmake --build . --target INSTALL --config Release

rem Copy wholesale to output directory.
xcopy C:\cb2\install %INSTALL_DIR% /O /X /E /H /K || goto error

rem Delete install temp directory
rmdir /q /s "C:\cb2\install" 2>NUL || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
