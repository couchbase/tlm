@echo on

set SRC_DIR=%1
set CBDEP=%2
set MINIFORGE_VERSION=%3
set PYTHON_VERSION=%4
set INSTALL_DIR=%5

rem Install and activate Miniforge3
%CBDEP% install -d . miniforge3 %MINIFORGE_VERSION%
call .\miniforge3-%MINIFORGE_VERSION%\Scripts\activate || goto error

rem Create and activate a builder environment, with our desired version of
rem python and the latest compatible conda-build/conda-pack/conda-verify.
rem It's important to build our local packages in an environment with the
rem same version of python that we will bundle in cbpy, and this is the
rem safest way to achieve that.
call conda create -y -n builder python=%PYTHON_VERSION% conda-build conda-pack conda-verify || goto error
call conda activate builder || goto error

rem Build our stubs and packages
dir /A /B "%SRC_DIR%/conda-pkgs/all" | findstr /R ".">NUL && (call conda build --output-folder .\conda-pkgs "%SRC_DIR%/conda-pkgs/all/*" || goto error) || echo No packages in all
dir /A /B "%SRC_DIR%/conda-pkgs/stubs" | findstr /R ".">NUL && (call conda build --output-folder .\conda-pkgs "%SRC_DIR%/conda-pkgs/stubs/*" || goto error) || echo No packages in stubs

rem Create cbpy environment
call conda create -y -n cbpy ^
  -c ./conda-pkgs -c conda-forge ^
  --override-channels --strict-channel-priority ^
  python=%PYTHON_VERSION% ^
  --file %SRC_DIR%\cb-dependencies.txt ^
  --file %SRC_DIR%\cb-dependencies-windows-amd64.txt ^
  --file %SRC_DIR%\cb-stubs.txt || goto error

rem Remove gmp (pycryptodome soft dep)
call conda list -n cbpy gmp | findstr gmp
if %ERRORLEVEL% EQU 0 call conda remove -n cbpy gmp -y --force

rem Pack cbpy and then unpack into final dir
call conda pack -n cbpy --output cbpy.tar || goto error
rmdir /s /q %INSTALL_DIR%
mkdir %INSTALL_DIR%
set TARBALL=%CD%\cbpy.tar
pushd %INSTALL_DIR%
cmake -E tar xf %TARBALL%
del %TARBALL%

rem Save the environment for future reference
mkdir env
call conda list -n cbpy > env/environment-windows-amd64.txt || goto error
call conda env export -n cbpy > env/environment-windows-amd64.yml || goto error

rem Deactivate builder environment, then base environment
call conda deactivate || goto error
call conda deactivate || goto error

rem Prune installation
dir
del api-ms-win-*.dll
rmdir /s /q conda-meta
rmdir /s /q include
rem We have Library, Lib, and libs, all different. Yay.
rem Lib\ seems to be the "real" python stuff. Library\bin contains .dlls for
rem C-linked packages like snappy and sqlite3; other parts of Library are
rem unnecessary. libs\ has nothing important for runtime.
rmdir /s /q libs
rmdir /s /q Lib\idlelib
rmdir /s /q Lib\lib2to3
rmdir /s /q Lib\tkinter
rmdir /s /q Library\cmake
rmdir /s /q Library\include
rmdir /s /q Library\lib
rmdir /s /q Scripts
rmdir /s /q tcl
rmdir /s /q Tools
popd

rem Quick installation test - we need to emulate the py-wrapper.c approach
rem and add Library\bin to PATH for the C-linked libraries to work
set PATH=%INSTALL_DIR%\Library\bin:%PATH%
%INSTALL_DIR%\python.exe "%SRC_DIR%/test_cbpy.py" || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
