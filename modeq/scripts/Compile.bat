@echo off
set GCC_EXEC_PREFIX=
set OLDPATH=%PATH%
pushd "%MOSHHOME%\..\MinGW\bin"
set PATH=%CD%
popd
mingw32-make -f %1
set RESULT=%ERRORLEVEL%
set PATH=%OLDPATH%
exit %RESULT%