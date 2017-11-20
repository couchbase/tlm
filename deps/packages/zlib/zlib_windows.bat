set INSTALL_DIR=%1

rem Build zlib libraries
call nmake -f win32\Makefile.msc || goto error

rem Copy right stuff to output directory.
mkdir %INSTALL_DIR%\bin
mkdir %INSTALL_DIR%\lib
mkdir %INSTALL_DIR%\include

copy *.lib %INSTALL_DIR%\lib || goto error
copy zlib1.dll %INSTALL_DIR%\bin || goto error

copy zconf.h %INSTALL_DIR%\include || goto error
copy zlib.h %INSTALL_DIR%\include || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
