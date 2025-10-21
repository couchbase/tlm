@echo off

if not defined tools_version (
    set tools_version=14.0
)

if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build" (
  set "tools_dir=C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build" (
  set "tools_dir=C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build" (
  set "tools_dir=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build" (
  set "tools_dir=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build"
) else (
  set "tools_dir=C:\Program Files (x86)\Microsoft Visual Studio %tools_version%\VC"
)
echo Using tools from %tools_dir%
if not defined source_root goto default_source_root

:target_arch
if not defined target_arch goto default_target_arch

:setup_arch
if /i "%target_arch%" == "amd64" goto setup_amd64
if /i "%target_arch%" == "x86" goto setup_x86

echo Unknown architecture: %target_arch%. Must be amd64 or x86
set ERRORLEVEL=1
goto eof

:default_source_root
set source_root=%CD%
echo source_root not set. It was automatically set to the current directory %source_root%.
goto target_arch

:default_target_arch
set target_arch=amd64
echo target_arch is not set. It was automatically set to %target_arch%.
goto setup_arch

:setup_x86
echo Setting up Visual Studio environment for x86
call "%tools_dir%\vcvarsall.bat" x86
goto setup_environment

:setup_amd64
echo Setting up Visual Studio environment for amd64
call "%tools_dir%\vcvarsall.bat" amd64
goto setup_environment

:setup_environment
rem Unfortunately we need to have all of the directories
rem we build dll's in in the path in order to run make
rem test in a module..

echo Setting compile environment for building Couchbase server
set OBJDIR=\build
set MODULEPATH=%SOURCE_ROOT%%OBJDIR%\platform
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\platform\extmeta
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\platform\cbcompress
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\platform\cbsocket
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\phosphor

set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\memcached
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\couchstore
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\magma
set MODULEPATH=%MODULEPATH%;%SOURCE_ROOT%%OBJDIR%\sigar\src
set PATH=%MODULEPATH%;%PATH%;%SOURCE_ROOT%\install\bin
set OBJDIR=
SET MODULEPATH=
cd %SOURCE_ROOT%
if "%target_arch%" == "amd64" set PATH=%PATH%;%SOURCE_ROOT%\install\x86\bin
goto eof

:missing_root
echo source_root should be set in the source root
set ERRORLEVEL=1
goto eof

:missing_target_arch
echo target_arch must be set in environment to x86 or amd64
set ERRORLEVEL=1
goto eof

:eof
