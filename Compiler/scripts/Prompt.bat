@echo off
REM %1 should be mingw32 or mingw64, if empty the latter is selected
REM Clear all environment variables that may interfere during compile and link phases.
set GCC_EXEC_PREFIX=
set CPLUS_INCLUDE_PATH=
set C_INCLUDE_PATH=
set LIBRARY_PATH=
set OLD_PATH=%PATH%
if not "%1"=="" (set OM_PLATFORM=%1) else (set OM_PLATFORM=mingw64)
set MINGW=%OPENMODELICAHOME%\msys\%OM_PLATFORM%
set ADDITIONAL_ARGS=
REM If OMDEV is set, use MinGW from there instead of OPENMODELICAHOME
REM It is not certain that release OMC is installed
if not %OMDEV%a==a set MINGW=%OMDEV%\tools\msys\%OM_PLATFORM%
REM echo OPENMODELICAHOME = %OPENMODELICAHOME% >> %1.log 2>&1
REM echo MINGW = %MINGW% >>%1.log 2>&1
set CURRENT_DIR="%CD%"

cd /D "%MINGW%\bin"
set PATH=%CD%;%CD%\..\..\usr\bin\;%OPENMODELICAHOME%\bin;%OPENMODELICAHOME%\lib\omc\msvc;%OPENMODELICAHOME%\lib\omc\cpp;%OPENMODELICAHOME%\lib\omc\cpp\msvc;
echo PATH = "%PATH%"
cd /D "%CURRENT_DIR%"

REM echo PATH = %PATH% >>%1.log 2>&1
REM echo CD = %CD% >>%1.log 2>&1
