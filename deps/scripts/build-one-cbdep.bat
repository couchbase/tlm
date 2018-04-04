cd deps\packages

rmdir /s /q winbuild

rem Make the output directory that the job expects
rmdir /s /q build\deps
mkdir build\deps

rem When compiling V8, Gyp expects the TMP variable to be set
set TMP=C:\Windows\Temp
rem Default value for source_root (ignored but must be set)
set source_root=%CD%

if "%DISTRO%" == "windows_msvc2017" (
  set tools_version=15.0
  goto do_build
)
if "%DISTRO%" == "windows_msvc2015" (
  set tools_version=14.0
  goto do_build
)
if "%DISTRO%" == "windows_msvc2013" (
  set tools_version=12.0
  goto do_build
)
rem Without year, VS version defaults to 2013
if "%DISTRO%" == "windows_msvc" (
  set tools_version=12.0
  goto do_build
)
if "%DISTRO%" == "windows_msvc2012" (
  set tools_version=11.0
  goto do_build
)

:do_build
set target_arch=amd64
call ..\..\win32\environment.bat %tools_version%
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
