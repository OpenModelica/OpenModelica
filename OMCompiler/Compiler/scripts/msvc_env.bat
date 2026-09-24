@echo off
REM Enters the Visual Studio developer environment (cl, nmake and the cmake
REM that comes with Visual Studio) unless its tools are already on the PATH.
REM Called by Compile.bat and by omc before running cmake for the msvc target.
REM
REM Arguments
REM 1 platform (msvc64|msvc32), msvc64 if omitted
REM
REM Exits with 1, saying so, when no Visual Studio with the C++ toolset is found.
where cl.exe >NUL 2>&1 && where nmake.exe >NUL 2>&1 && exit /b 0
set VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe
if not exist "%VSWHERE%" set VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe
if not exist "%VSWHERE%" goto :NOT_FOUND
set VSPATH=
for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set VSPATH=%%I
if "%VSPATH%"=="" goto :NOT_FOUND
set VCVARS=%VSPATH%\VC\Auxiliary\Build\vcvars64.bat
if /I "%1"=="msvc32" set VCVARS=%VSPATH%\VC\Auxiliary\Build\vcvars32.bat
if not exist "%VCVARS%" goto :NOT_FOUND
REM Its banner goes to NUL, not the caller's log: a batch called with the log
REM redirected keeps that handle open, and nmake then cannot write there.
call "%VCVARS%" > NUL 2>&1
if errorlevel 1 goto :NOT_FOUND
exit /b 0

:NOT_FOUND
echo No Visual Studio with the C++ toolset found: install the Build Tools with the
echo Desktop development with C++ workload, or run omc from a Developer Command Prompt.
exit /b 1
