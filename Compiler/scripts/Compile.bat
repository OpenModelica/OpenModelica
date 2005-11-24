@echo off
set GCC_EXEC_PREFIX=
set OLDPATH=%PATH%
pushd "%OPENMODELICAHOME%\MinGW\bin"
set PATH=%CD%
popd
mingw32-make -f %1.makefile >nul
set RESULT=%ERRORLEVEL%
set PATH=%OLDPATH%
rem exit %RESULT%