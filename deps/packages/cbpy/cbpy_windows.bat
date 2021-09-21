@echo on

set SRC_DIR=%1
set CBDEP=%2
set MINIFORGE_VERSION=%3
set INSTALL_DIR=%4

rem Install and activate Miniforge3
%CBDEP% install -d . miniforge3 %MINIFORGE_VERSION%
call .\miniforge3-%MINIFORGE_VERSION%\Scripts\activate || goto error

rem Install conda-build (to build our 'faked' packages) and conda-pack
call conda install -y conda-build conda-pack conda-verify || goto error

rem Build our local stub packages
call conda build --output-folder .\conda-pkgs %SRC_DIR%\conda-pkgs\all\* || goto error

rem Create cbpy environment
call conda create -y -n cbpy || goto error

rem Populate cbpy environment - conda likes / rather than \
call conda install -y ^
  -n cbpy ^
  -c ./conda-pkgs -c conda-forge ^
  --override-channels --strict-channel-priority ^
  --file %SRC_DIR%/environment-base.txt ^
  --file %SRC_DIR%/environment-win.txt || goto error

rem Pack cbpy and then unpack into final dir
call conda pack -n cbpy --output cbpy.tar || goto error
call conda deactivate || goto error
rmdir /s /q %INSTALL_DIR%
mkdir %INSTALL_DIR%
set TARBALL=%CD%\cbpy.tar
pushd %INSTALL_DIR%
cmake -E tar xf %TARBALL%
del %TARBALL%

rem Prune installation
del api-ms-win-*.dll
rmdir /s /q conda-meta
rmdir /s /q include
rem We have Library, Lib, and libs, all different. Yay.
rmdir /s /q Library
rmdir /s /q libs
rmdir /s /q Lib\distutils
rmdir /s /q Lib\idlelib
rmdir /s /q Lib\lib2to3
rmdir /s /q Lib\tkinter
rmdir /s /q Scripts
rmdir /s /q tcl
rmdir /s /q Tools
del Uninstall-cbpy.exe
del _conda.exe
popd

rem Quick installation test
%INSTALL_DIR%\python.exe -c "import requests" || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
