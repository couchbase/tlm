cd deps\packages

rem Make the output directory that the job expects
mkdir build\deps

rem Build amd64 first

set target_arch=amd64
call ..\..\win32\environment.bat
mkdir winbuild
cd winbuild
cmake .. -G "NMake Makefiles" -DPACKAGE=%PACKAGE% || goto error
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
cmake .. -G "NMake Makefiles" -DPACKAGE=%PACKAGE% || goto error
cmake --build . --target %PACKAGE% || goto error
cd ..
xcopy winbuild\deps build\deps /s /e /y

goto eof

:error
echo Failed with error %ERRORLEVEL%.
exit /b %ERRORLEVEL%

:eof
