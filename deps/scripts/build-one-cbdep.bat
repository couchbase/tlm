rem Build amd64 first

set target_arch=amd64
cd deps/packages
mkdir build
cd build
cmake .. || goto error
cmake --build . --target %PACKAGE% || goto error

rem Clean up

cd ..
rmdir /s /q build

rem Build again for x86

set target_arch=x86
cd deps/packages
mkdir build
cd build
cmake .. || goto error
cmake --build . --target %PACKAGE% || goto error

goto eof

:error
echo Failed with error %ERRORLEVEL%.
exit /b %ERRORLEVEL%

:eof
