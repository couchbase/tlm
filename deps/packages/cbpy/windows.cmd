@echo on
set MINIFORGE_VERSION="4.10.3-5"
set WD=c:\temp\cbpy2
rem Note: this won't work interactively, if you're doing these steps by hand
rem       set SCRIPTPATH manually
set SCRIPTPATH=%~dp0
rmdir %WD% /s /q || goto error
mkdir %WD%
cd %WD%

powershell.exe -Command "invoke-webrequest -UseBasicParsing -uri https://packages.couchbase.com/cbdep/1.0.4/cbdep-1.0.4-windows.exe -outfile .\cbdep.exe"

.\cbdep.exe install -d . miniforge3 %MINIFORGE_VERSION%

call .\miniforge3-%MINIFORGE_VERSION%\Scripts\activate || goto error
call conda install -y conda-build conda-pack conda-verify || goto error
dir /A /B %SCRIPTPATH%\conda-pkgs\stubs | findstr /R ".">NUL && (call conda build --output-folder .\conda-pkgs %SCRIPTPATH%\conda-pkgs\stubs\* || goto error) || echo No packages in stubs
dir /A /B %SCRIPTPATH%\conda-pkgs\all | findstr /R ".">NUL && (call conda build --output-folder .\conda-pkgs %SCRIPTPATH%\conda-pkgs\all\* || goto error) || echo No packages in all
echo ACTIVATING ENV
call conda create -y -n cbpy || goto error
echo ENV ACTIVATED

rem Get the list of deps we'll want to `conda install`
powershell.exe -Command "((Select-String -Path %SCRIPTPATH%\cb-dependencies.txt -Pattern '^[A-Za-z0-9\-]*=' -All | foreach {$_.Line}) -Join ' ') + ' ' | Out-File -NoNewline -Encoding ASCII %WD%\deps"
powershell.exe -Command "((Select-String -Path %SCRIPTPATH%\cb-stubs.txt -Pattern '^[A-Za-z0-9\-]*=' -All | foreach {$_.Line}) -Join ' ') + ' ' | Out-File -NoNewline -Encoding ASCII -Append %WD%\deps"
set /P deps=<%WD%\deps

call conda activate cbpy || goto error
call conda install -y -c ./conda-pkgs %deps% || goto error
call conda update -y -c ./conda-pkgs --update-all || goto error
call conda list || goto error

goto :eof

:error
echo Failed with error %ERRORLEVEL%
exit /B %ERRORLEVEL%
