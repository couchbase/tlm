setlocal
set PATH=%PATH%;c:\cygwin\bin

set INSTALL_DIR=%1

set configure_args=CC=cl CXX=cl --prefix=%INSTALL_DIR% --with-jemalloc-prefix=je_ --disable-cache-oblivious --disable-zone-allocator --enable-prof --disable-cxx
sh -c "./autogen.sh %configure_args%" || exit /b
rem Set up install directory paths
sh -c "mkdir -p %INSTALL_DIR% && mkdir -p %INSTALL_DIR%/bin && mkdir -p %INSTALL_DIR%/lib && mkdir -p %INSTALL_DIR%/include" || exit /b

rem Make the header files and bin directory
make install_include install_bin || exit /b
rem Make jemalloc.dll using msbuild.exe and jemalloc.vcxproj as this is now the supported build method on Windows
msbuild .\msvc\projects\vc2017\jemalloc\jemalloc.vcxproj -property:Configuration=Release -maxcpucount || exit /b

sh -c "rm msvc/projects/vc2017/jemalloc/x64/Debug/jemallocd.pdb"
msbuild .\msvc\projects\vc2017\jemalloc\jemalloc.vcxproj -property:Configuration=Debug -maxcpucount || exit /b

rem Copy the build output to the install directory
sh -c "mkdir -p %INSTALL_DIR%/bin/Release/" || exit /b
sh -c "mkdir -p %INSTALL_DIR%/lib/Release/" || exit /b
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Release/jemalloc.dll %INSTALL_DIR%/bin/Release/" || exit /b
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Release/jemalloc.lib %INSTALL_DIR%/lib/Release/" || exit /b
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Release/jemalloc.pdb %INSTALL_DIR%/lib/Release/" || exit /b
sh -c "mkdir -p %INSTALL_DIR%/bin/Debug/" || exit /b
sh -c "mkdir -p %INSTALL_DIR%/lib/Debug/" || exit /b
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Debug/jemallocd.dll %INSTALL_DIR%/bin/Debug/" || exit /b
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Debug/jemallocd.lib %INSTALL_DIR%/lib/Debug/" || exit /b
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Debug/jemallocd.pdb %INSTALL_DIR%/lib/Debug/" || exit /b

rem Need strings.h and more on Windows. Jemalloc supplies it, copy manually.
cp -r include/msvc_compat %INSTALL_DIR%/include || exit /b

rem Debugging Assertions build - Built against the Release CRT so can be dropped into a normal Release/RelWithDebInfo build.
sh -c "./autogen.sh %configure_args% --enable-debug" || exit /b
msbuild .\msvc\projects\vc2017\jemalloc\jemalloc.vcxproj -property:Configuration=Release -maxcpucount || exit /b
sh -c "mkdir -p %INSTALL_DIR%/bin/ReleaseAssertions/" || exit /b
sh -c "mkdir -p %INSTALL_DIR%/lib/ReleaseAssertions/" || exit /b
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Release/jemalloc.dll %INSTALL_DIR%/bin/ReleaseAssertions/" || exit /b
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Release/jemalloc.lib %INSTALL_DIR%/lib/ReleaseAssertions/" || exit /b
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Release/jemalloc.pdb %INSTALL_DIR%/lib/ReleaseAssertions/" || exit /b
