@echo off
REM Clear all environment variables that may interfere during compile and link phases.
set GCC_EXEC_PREFIX=
set CPLUS_INCLUDE_PATH=
set C_INCLUDE_PATH=
set LIBRARY_PATH=
set OLD_PATH=%PATH%
set MINGW=%OPENMODELICAHOME%\MinGW
set ADDITIONAL_ARGS=
REM If OMDEV is set, use MinGW from there instead of OPENMODELICAHOME
REM It is not certain that release OMC is installed
if not %OMDEV%a==a set MINGW=%OMDEV%\tools\MinGW
REM echo OPENMODELICAHOME = %OPENMODELICAHOME% >> %1.log 2>&1
REM echo MINGW = %MINGW% >>%1.log 2>&1
set CURRENT_DIR="%CD%"
cd /D "%MINGW%\bin" >>%CURRENT_DIR%\%1.log 2>&1
set PATH=%CD%;%CD%\..\libexec\gcc\mingw32\4.4.0\; >>%CURRENT_DIR%\%1.log 2>&1
cd /D "%CURRENT_DIR%" >>%CURRENT_DIR%\%1.log 2>&1
REM echo PATH = %PATH% >>%1.log 2>&1
REM echo CD = %CD% >>%1.log 2>&1
if /I "%2"=="msvc" (goto :MSVC)
if /I "%2"=="msvc10" (goto :MSVC100)
if /I "%2"=="msvc12" (goto :MSVC110)
if /I "%2"=="msvc13" (goto :MSVC120)
if /I "%2"=="msvc15" (goto :MSVC140) else (goto :MINGW)

:MSVC
REM echo "MSVC"
REM check if msvc is there
if defined VS140COMNTOOLS (goto :MSVC140)
if defined VS120COMNTOOLS (goto :MSVC120)
if defined VS110COMNTOOLS (goto :MSVC110)
if not defined VS100COMNTOOLS (goto :MINGW)
goto :MSVC100



:MSVC100
REM "Use Visual Studio 2010"
set MSVCHOME=%VS100COMNTOOLS%..\..\VC
if not exist "%MSVCHOME%\vcvarsall.bat" (goto :MINGW)
set PATHTMP=%PATH%
set PATH=%OLD_PATH%
call "%MSVCHOME%\vcvarsall.bat" >> %1.log 2>&1
goto :MSVCCOMPILE



:MSVC110
REM "Use Visual Studio 2012"
set MSVCHOME=%VS110COMNTOOLS%..\..\VC
if not exist "%MSVCHOME%\vcvarsall.bat" (goto :MINGW)
set PATHTMP=%PATH%
set PATH=%OLD_PATH%
call "%MSVCHOME%\vcvarsall.bat" >> %1.log 2>&1
goto :MSVCCOMPILE



:MSVC120
REM "Use Visual Studio 2013"
echo "msvc120"
set MSVCHOME=%VS120COMNTOOLS%..\..\VC
if not exist "%MSVCHOME%\vcvarsall.bat" (goto :MINGW)
set PATHTMP=%PATH%
set PATH=%OLD_PATH%
call "%MSVCHOME%\vcvarsall.bat" >> %1.log 2>&1
goto :MSVCCOMPILE



:MSVC140
REM "Use Visual Studio 2015"
set MSVCHOME=%VS140COMNTOOLS%..\..\VC
if not exist "%MSVCHOME%\vcvarsall.bat" (goto :MINGW)
set PATHTMP=%PATH%
set PATH=%OLD_PATH%
call "%MSVCHOME%\vcvarsall.bat" >> %1.log 2>&1
goto :MSVCCOMPILE




:MSVCCOMPILE
set MAKE=
set MAKEFLAGS=
nmake /a /f %1.makefile >> %1.log 2>&1
set RESULT=%ERRORLEVEL%
echo RESULT: %RESULT% >> %1.log 2>&1
goto :Final


:MINGW
REM echo "MINGW"
if "%3"=="parallel" set ADDITIONAL_ARGS=-j%NUMBER_OF_PROCESSORS%
%MinGW%\bin\mingw32-make -f %1.makefile %ADDITIONAL_ARGS% >> %1.log 2>&1
set RESULT=%ERRORLEVEL%
echo RESULT: %RESULT% >> %1.log 2>&1
goto :Final


:Final
set PATH=%OLD_PATH%
set OLD_PATH=
@%COMSPEC% /C exit %RESULT%
