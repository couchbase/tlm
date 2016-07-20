cd deps\packages

rem Make the output directory that the job expects
mkdir build\deps

rem Default value for source_root (ignored but must be set)
set source_root=%CD%

rem Build amd64 first

set target_arch=amd64
call ..\..\win32\environment.bat
mkdir winbuild
cd winbuild
cmake -D CMAKE_GENERATOR_PLATFORM=x64 .. || goto error
cmake --build . --target %PACKAGE% || goto error
cd ..
xcopy winbuild\deps build\deps /s /e /y

rem Clean up
rmdir /s /q winbuild

rem Build again for x86

set target_arch=x86
call ..\..\win32\environment.bat
mkdir winbuild
cd winbuild
cmake .. || goto error
cmake --build . --target %PACKAGE% || goto error
cd ..
xcopy winbuild\deps build\deps /s /e /y

goto eof

:error
echo Failed with error %ERRORLEVEL%.
exit /b %ERRORLEVEL%

:eof
