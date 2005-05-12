@echo off
if not exist "%1" goto end

if exist %~n1.sig goto maketest
"%~dp0w32-rml2sig.exe" %1 > %~n1.sig
goto end

:maketest
"%~dp0w32-rml2sig.exe" %1 > %~n1.tmp
fc %~n1.sig %~n1.tmp > nul

if errorlevel 1 goto diff
goto nodiff

:diff
echo New signature
del /Q %~n1.sig
rename %~n1.tmp %~n1.sig
goto end

:nodiff
echo No difference
del /Q %~n1.tmp

:end

