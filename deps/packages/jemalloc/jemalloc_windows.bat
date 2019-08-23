setlocal
set PATH=%PATH%;c:\cygwin\bin

set INSTALL_DIR=%1

sh -c "./autogen.sh CC=cl --prefix=%INSTALL_DIR% --with-jemalloc-prefix=je_ --disable-cache-oblivious --disable-zone-allocator --enable-prof"
rem Set up install directory paths
sh -c "mkdir -p %INSTALL_DIR% && mkdir -p %INSTALL_DIR%/bin && mkdir -p %INSTALL_DIR%/lib && mkdir -p %INSTALL_DIR%/include"

rem Make the header files and bin directory
make install_include install_bin
rem Make jemalloc.dll using msbuild.exe and jemalloc.vcxproj as this is now the supported build method on Windows
msbuild .\msvc\projects\vc2017\jemalloc\jemalloc.vcxproj -property:Configuration=Release -maxcpucount:8

rem Copy the build output to the install directory
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Release/jemalloc.dll %INSTALL_DIR%/lib"
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Release/jemalloc.lib %INSTALL_DIR%/lib"
sh -c "cp -f msvc/projects/vc2017/jemalloc/x64/Release/jemalloc.pdb %INSTALL_DIR%/lib"

rem Need strings.h and more on Windows. Jemalloc supplies it, copy manually.
cp -r include/msvc_compat %INSTALL_DIR%/include
