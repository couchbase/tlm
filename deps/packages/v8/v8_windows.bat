rem Error check
where python && goto :haspython

set INSTALL_DIR=%1

rem Get our vendored copy of Google's depot_tools.
rem The v8-5.9 branch in our mirror is set to the version as of
rem early September 2017, when this v8 package was created.
if not exist depot_tools (
    git clone -b couchbasedeps-v8-5.9 git://github.com/couchbasedeps/depot_tools || goto error
)
set PATH=%cd%\depot_tools;%PATH%

rem Disable gclient auto-update (won't work anyway since we're using a
rem vendored copy)
set DEPOT_TOOLS_UPDATE=0

rem Do not know why this is required since we're not using gyp, but
rem it fails deep in the bowels of gclient setup if we don't set it
set GYP_MSVS_VERSION=2015

rem Disable gclient getting Google-internal versions of stuff
set DEPOT_TOOLS_WIN_TOOLCHAIN=0

rem Use gclient (from depot_tools) to sync our vendored version
rem of v8. Note: this is not truly vendored, as both depot_tools
rem and the v8 build download many things from Google as part
rem of the build. Therefore we can't guarantee this will work
rem indefinitely. I could not find a way around this issue.
echo solutions = [ { "url": "https://github.com/couchbasedeps/v8.git@5.9.223","managed": False, "name": "v8", "deps_file": "DEPS", "custom_deps": { "v8/third_party/icu": "https://chromium.googlesource.com/chromium/deps/icu.git@origin/chromium/59staging" }, }, ]; > .gclient
call gclient sync --noprehooks --nohooks || goto error
call gclient runhooks || goto error
echo on

rem Actual v8 configure and build steps - we build debug and release.
cd v8
rem Use double-quoting here because .bat quote removal is inscrutable.
set V8_ARGS=target_cpu=""x64"" is_component_build=true v8_enable_backtrace=true v8_use_snapshot=true v8_use_external_startup_data=false v8_enable_i18n_support=true v8_test_isolation_mode=""noop""
call gn gen out.gn/Release --args="%V8_ARGS% is_debug=false" || goto error
echo on
call ninja -C out.gn/Release || goto error
echo on
call gn gen out.gn/Debug --args="%V8_ARGS% is_debug=true" || goto error
echo on
call ninja -C out.gn/Debug || goto error
echo on

rem Copy right stuff to output directory.
mkdir %INSTALL_DIR%\lib\Release
mkdir %INSTALL_DIR%\lib\Debug
mkdir %INSTALL_DIR%\include\libplatform

cd out.gn\release
copy v8.dll* %INSTALL_DIR%\lib\Release || goto error
copy v8_lib* %INSTALL_DIR%\lib\Release || goto error
copy icu*.* %INSTALL_DIR%\lib\Release || goto error
del %INSTALL_DIR%\lib\Release\*.ilk || goto error

cd ..\..\out.gn\debug
copy v8.dll* %INSTALL_DIR%\lib\Debug || goto error
copy v8_lib* %INSTALL_DIR%\lib\Debug || goto error
copy icu*.* %INSTALL_DIR%\lib\Debug || goto error
del %INSTALL_DIR%\lib\Debug\*.ilk || goto error

cd ..\..\include
copy v8*.h %INSTALL_DIR%\include || goto error
cd libplatform
copy *.h %INSTALL_DIR%\include\libplatform || goto error

goto :eof

:haspython
echo Python is on the system path - build will fail, aborting
echo Rename python.exe to something else during this build
exit /B 1

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
