setlocal
set PATH=%PATH%;c:\cygwin\bin

set INSTALL_DIR=%1

sh -c "./autogen.sh CC=cl --prefix=%INSTALL_DIR% --with-jemalloc-prefix=je_ --disable-cache-oblivious --disable-zone-allocator --enable-prof"

make build_lib_shared
make install_lib_shared install_include install_bin

rem The standard install rules don't install the import library or PDB files - do it manually.
cp lib\jemalloc.lib lib\jemalloc.pdb %INSTALL_DIR%\lib
