set INSTALL_DIR=%1
set DEPS=%WORKSPACE%\deps

rem Apply patch for building boringssl with latest MSVC2017
git apply %~dp0\win_msvc2017_boringssl.patch

rem Download cbdep and use it to get Golang
set SITE=https://packages.couchbase.com/cbdep/cbdep-0.8.0-windows.exe
set FILENAME=%WORKSPACE%\cbdep.exe
powershell -command "& { (New-Object Net.WebClient).DownloadFile('%SITE%', '%FILENAME%') }" || goto error
%WORKSPACE%\cbdep.exe install -d "%DEPS%" golang 1.10.3

set GOPATH=%WORKSPACE%
set GOROOT=%DEPS%\go1.10.3
set PATH=%GOROOT%\bin;%PATH%

rem Build grpc binaries and libraries
md .build
cd .build
cmake .. -G Ninja ^
  -D CMAKE_C_COMPILER=cl -D CMAKE_CXX_COMPILER=cl ^
  -D CMAKE_BUILD_TYPE=RelWithDebInfo ^
  -D CMAKE_INSTALL_PREFIX="%INSTALL_DIR%" || goto error
ninja install || goto error

rem Copy stuff that grpc build doesn't think to include in install directory
copy *.lib %INSTALL_DIR%\lib || goto error
copy grpc_cpp_plugin.exe %INSTALL_DIR%\bin || goto error
copy third_party\protobuf\libprotobuf.lib %INSTALL_DIR%\lib || goto error
copy third_party\zlib\zlib*.lib %INSTALL_DIR%\lib || goto error
copy third_party\boringssl\gtest.lib %INSTALL_DIR%\lib || goto error
copy third_party\boringssl\crypto\crypto.lib %INSTALL_DIR%\lib || goto error
copy third_party\boringssl\decrepit\decrepit.lib %INSTALL_DIR%\lib
copy third_party\boringssl\ssl\ssl.lib %INSTALL_DIR%\lib || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
