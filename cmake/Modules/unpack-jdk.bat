@echo on
set jdkexe=%~f1
set outdir=%~f2
set pwd=%~dp0

mkdir %outdir% || goto error
cd %outdir% || goto error

rem Many thanks to https://stackoverflow.com/a/6571736/1425601
7z e %jdkexe% .rsrc/1033/JAVA_CAB10/111 || goto error
7z e 111 || goto error
del 111 || goto error
7z x tools.zip || goto error
del tools.zip || goto error
for /r %%x in (*.pack) do .\bin\unpack200 -r "%%x" "%%~dx%%~px%%~nx.jar" || goto error

goto eof

:error
echo "Script failed with %ERRORLEVEL%"
cd %pwd%
exit /B 1

:eof
cd %pwd%
