set INSTALL_DIR=%1

rem Need to add ActivePerl to path
set PATH=C:\Perl64\bin;%PATH%

rem Build OpenSSL binary and libraries
call perl Configure VC-WIN64A --prefix=./build || goto error
call ms\do_win64a.bat || goto error
call nmake -f ms\ntdll.mak || goto error
call nmake -f ms\ntdll.mak install || goto error
call xcopy /IE .\build %INSTALL_DIR% || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
