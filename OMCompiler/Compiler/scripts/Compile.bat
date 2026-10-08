@echo off
REM Builds the C code OpenModelica generated for a model, on Windows.
REM Called by CevalScript.compileModel and by OMEdit.
REM
REM Arguments
REM 1 fileprefix
REM 2 target (gcc|msvc)
REM 3 platform (ucrt64|mingw64|msvc64|msvc32)
REM 4 serial/parallel
REM 5 linkType (dynamic|static)
REM 6 number of processors
REM 7 LOGGING 0/1
REM
REM The target says which makefile dialect omc generated: "gcc" is a GNU
REM makefile for mingw32-make, "msvc" an nmake one. Set OMC_TOOLCHAIN=clang-cl
REM to build the msvc target with clang-cl rather than cl.
if not "%5"=="" (set LINK_TYPE=%5) else (set LINK_TYPE=dynamic)
if not "%6"=="" (set NUM_PROCS=%6) else (set NUM_PROCS=%NUMBER_OF_PROCESSORS%)
if not "%7"=="" (set LOGGING=%7) else (set LOGGING=1)
set OM_PLATFORM=%3
REM Clear all environment variables that may interfere during compile and link phases.
set GCC_EXEC_PREFIX=
set CPLUS_INCLUDE_PATH=
set C_INCLUDE_PATH=
set LIBRARY_PATH=
set OLD_PATH=%PATH%
set RESULT=1
for %%I in ("%OPENMODELICAHOME%") do set OPENMODELICAHOME=%%~sI
for %%I in ("%CD%") do set CURRENT_DIR=%%~sI
REM The MinGW branch cd's away, so name the log absolutely.
set LOGFILE=%CURRENT_DIR%\%1.log
set MAKEFILE=%1.makefile

if /I "%2"=="msvc"   goto :MSVC
if /I "%2"=="msvc10" goto :MSVC
if /I "%2"=="msvc12" goto :MSVC
if /I "%2"=="msvc13" goto :MSVC
if /I "%2"=="msvc15" goto :MSVC
if /I "%2"=="msvc19" goto :MSVC
goto :MINGW

REM ---------------------------------------------------------------- MinGW ---
REM An OMDev or OpenModelica installation ships its toolchain under
REM tools\msys\<platform>; a stand-alone MSYS2 is used through the PATH.
:MINGW
set MINGW=%OPENMODELICAHOME%\tools\msys\%OM_PLATFORM%
if not "%OMDEV%"=="" set MINGW=%OMDEV%\tools\msys\%OM_PLATFORM%
set MINGW_MAKE=
if not exist "%MINGW%\bin\mingw32-make.exe" goto :MINGW_ON_PATH
cd /D "%MINGW%\bin"
set PATH=%CD%;%CD%\..\..\usr\bin;
cd /D "%CURRENT_DIR%"
set MINGW_MAKE=%MINGW%\bin\mingw32-make.exe
goto :MINGW_BUILD

:MINGW_ON_PATH
for %%I in (mingw32-make.exe) do set MINGW_MAKE=%%~$PATH:I
if "%MINGW_MAKE%"=="" for %%I in (make.exe) do set MINGW_MAKE=%%~$PATH:I
if "%MINGW_MAKE%"=="" goto :NO_MINGW

:MINGW_BUILD
set ADDITIONAL_ARGS=
if "%4"=="parallel" set ADDITIONAL_ARGS=-j%NUM_PROCS%
call :RUN "%MINGW_MAKE%" -w -f %MAKEFILE% OMC_LDFLAGS_LINK_TYPE=%LINK_TYPE% %ADDITIONAL_ARGS%
goto :Final

:NO_MINGW
call :FAIL No MinGW toolchain found. Searched %MINGW%\bin\mingw32-make.exe and the PATH.
call :FAIL Install OMDev, or MSYS2 from https://www.msys2.org with the packages
call :FAIL mingw-w64-ucrt-x86_64-gcc and mingw-w64-ucrt-x86_64-make,
call :FAIL or build with MSVC instead: omc --target=msvc
goto :Final

REM ----------------------------------------------------------------- MSVC ---
:MSVC
call "%~dp0msvc_env.bat" %OM_PLATFORM%
if errorlevel 1 goto :NO_MSVC
set MAKE=
set MAKEFLAGS=
set OMC_CC=cl
if /I "%OMC_TOOLCHAIN%"=="clang-cl" set OMC_CC=clang-cl
call :RUN nmake /nologo /f %MAKEFILE% CC=%OMC_CC% CXX=%OMC_CC%
goto :Final

:NO_MSVC
call :FAIL No MSVC toolchain found.
call :FAIL Install the Visual Studio Build Tools with the Desktop development
call :FAIL with C++ workload, or run this from a Developer Command Prompt.
goto :Final

REM ------------------------------------------------------------------------
:Final
set PATH=%OLD_PATH%
set OLD_PATH=
@%COMSPEC% /C exit %RESULT%
EXIT /B %ERRORLEVEL%

REM Run the build, honouring LOGGING, and leave its exit code in RESULT.
:RUN
if "%LOGGING%"=="1" (
  %* >> "%LOGFILE%" 2>&1
) else (
  %*
)
set RESULT=%ERRORLEVEL%
if "%LOGGING%"=="1" echo RESULT: %RESULT% >> "%LOGFILE%"
EXIT /B 0

REM Report a setup problem where omc will find it: the model's .log file.
:FAIL
echo %*
if "%LOGGING%"=="1" echo %*>> "%LOGFILE%"
set RESULT=1
EXIT /B 0
