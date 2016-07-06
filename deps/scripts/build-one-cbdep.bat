cd deps\packages

rem Make the output directory that the job expects
mkdir build\deps

rem When compiling V8, Gyp expects the TMP variable to be set
set TMP=C:\Windows\Temp

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

goto eof

:error
echo Failed with error %ERRORLEVEL%.
exit /b %ERRORLEVEL%

:eof
