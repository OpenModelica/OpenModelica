@echo off
cmd /c "%VS90COMNTOOLS%vsvars32.bat && nmake -f %1.msvc.makefile >%1.log 2<&1"
set RESULT=%ERRORLEVEL%
exit /B %RESULT%
