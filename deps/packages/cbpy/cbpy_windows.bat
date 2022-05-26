@echo on

set SRC_DIR=%1
set CBDEP=%2
set MINICONDA_VERSION=%3
set INSTALL_DIR=%4

rem Install and activate Miniconda3
%CBDEP% install -d . miniconda3-py39 %MINICONDA_VERSION%
call .\miniconda3-%MINICONDA_VERSION%\Scripts\activate || goto error

rem Install conda-build and constructor
call conda install -y conda-build=3.21.8 constructor=3.2.1 nsis=3.01=8 || goto error

rem Build our local stub packages
call conda build --output-folder .\conda-pkgs %SRC_DIR%\conda-pkgs\* || goto error

rem Build bespoke cbpy environment
call conda env create -p .\cbpy-environment -f %SRC_DIR%\environment.yaml --force || goto error
call conda env update -p .\cbpy-environment -f %SRC_DIR%\environment-win.yaml || goto error

rem Construct cbpy
mkdir constructor-cache
call constructor --verbose --cache-dir .\constructor-cache --output-dir %INSTALL_DIR% %SRC_DIR% || goto error
ren %INSTALL_DIR%\cbpy-installer cbpy-installer.exe

rem Quick installation test
call conda deactivate || goto error
start /wait %INSTALL_DIR%\cbpy-installer.exe /NoRegistry=1 /S /D=%CD%\cbpy || goto error
.\cbpy\python.exe -c "import requests" || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
