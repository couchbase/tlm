set INSTALL_DIR=%1

rem Build pcre libraries
md .build
cd .build
cmake .. -G "Ninja" ^
  -D CMAKE_INSTALL_PREFIX=%INSTALL_DIR% ^
  -D CMAKE_BUILD_TYPE=RelWithDebInfo ^
  -D BUILD_SHARED_LIBS=ON || goto error
ninja install || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
