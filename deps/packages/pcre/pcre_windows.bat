set INSTALL_DIR=%1

rem Have to ensure we do NOT use MSVC

rem Build pcre libraries
md .build
cd .build
cmake .. -G "Ninja" ^
  -D CMAKE_C_COMPILER=gcc ^
  -D CMAKE_CXX_COMPILER=g++ ^
  -D CMAKE_INSTALL_PREFIX=%INSTALL_DIR% ^
  -D CMAKE_BUILD_TYPE=RelWithDebInfo ^
  -D BUILD_SHARED_LIBS=ON || goto error
ninja install || goto error

rem Should be called libpcre.dll if built by MinGW
if exist %INSTALL_DIR%\bin\pcre.dll (
  echo "OH NO WE BUILT WITH MSVC"
  set ERRORLEVEL=5
  goto error
)
goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
