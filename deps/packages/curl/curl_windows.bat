set INSTALL_DIR=%1

set OUTPUT_DIR=builds\libcurl-vc12-x64-release-dll-ipv6-sspi-winssl
set OBJLIB_DIR=%OUTPUT_DIR%-obj-lib

mkdir %OBJLIB_DIR%\vauth
mkdir %OBJLIB_DIR%\vtls

call .\buildconf.bat || goto error
cd winbuild
call nmake -f Makefile.vc mode=dll VC=12 MACHINE=x64 DEBUG=no GEN_PDB=yes || goto error

cd ..
xcopy %OUTPUT_DIR% %INSTALL_DIR% /s || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
