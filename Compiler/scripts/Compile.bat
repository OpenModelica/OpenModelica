@echo off
REM Clear all environment variables that may interfere during compile and link phases.
set GCC_EXEC_PREFIX=
set CPLUS_INCLUDE_PATH=
set C_INCLUDE_PATH=
set LIBRARY_PATH=
set OLD_PATH=%PATH%
set MINGW=%OPENMODELICAHOME%\MinGW
REM If OMDEV is set, use MinGW from there instead of OPENMODELICAHOME
REM It is not certain that release OMC is installed
if not %OMDEV%a==a set MINGW=%OMDEV%\tools\MinGW
REM echo OPENMODELICAHOME = %OPENMODELICAHOME% > %1.log 2>&1
REM echo MINGW = %MINGW% >%1.log 2>&1
set CURRENT_DIR="%CD%"
cd /D "%MINGW%\bin" >>%CURRENT_DIR%\%1.log 2>&1
set PATH=%CD%;%CD%\..\libexec\gcc\mingw32\4.4.0\; >>%CURRENT_DIR%\%1.log 2>&1
cd /D "%CURRENT_DIR%" >>%CURRENT_DIR%\%1.log 2>&1
REM echo PATH = %PATH% >>%1.log 2>&1
REM echo CD = %CD% >>%1.log 2>&1
%MinGW%\bin\mingw32-make -f %1.makefile >>%1.log 2>&1
set RESULT=%ERRORLEVEL%
set PATH=%OLD_PATH%
set OLD_PATH=
exit %RESULT%