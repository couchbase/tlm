set INSTALL_DIR=%1

rem Build pcre libraries
call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat" x64
md .build
cd .build
cmake .. -G "NMake Makefiles" -DCMAKE_INSTALL_PREFIX=%INSTALL_DIR% -D CMAKE_BUILD_TYPE=RelWithDebInfo || goto error
cmake --build . --target INSTALL --config Release || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
