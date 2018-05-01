@echo on

set INSTALL_DIR=%1
set SCRIPT_DIR=%2
@rem PLATFORM and OpenSSL Dir arg not needed yet

@echo Download pre-built Erlang
powershell -Command "Invoke-WebRequest http://erlang.org/download/otp_win64_20.3.exe -OutFile otp.exe"

@echo Silent install
start /wait otp.exe /S /D=C:\erlang

@echo Copy where cbdeps build expects it
xcopy /Q /I /E C:\erlang\* %INSTALL_DIR%

@echo Silent uninstall
start /wait C:\erlang\Uninstall.exe /S

@echo Prune install dir
rmdir /s /q %INSTALL_DIR%\doc
del %INSTALL_DIR%\Install* %INSTALL_DIR%\Uninstall* %INSTALL_DIR%\README*
rmdir /s /q %INSTALL_DIR%\lib\wx-1.1
rmdir /s /q %INSTALL_DIR%\lib\wx-1.8.3
rmdir /s /q %INSTALL_DIR%\lib\jinterface-1.8.1
rmdir /s /q %INSTALL_DIR%\lib\megaco-3.18.3
rmdir /s /q %INSTALL_DIR%\lib\observer-2.7
rmdir /s /q %INSTALL_DIR%\lib\debugger-4.2.4

@echo Copy in cbdeps package bits
copy %SCRIPT_DIR%\erl.ini.in %INSTALL_DIR%
copy %SCRIPT_DIR%\CMakeLists_package.txt %INSTALL_DIR%\CMakeLists.txt
