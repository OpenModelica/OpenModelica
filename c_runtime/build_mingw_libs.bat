@echo off

rem Use this script to build MinGW versions of the runtime libs
rem OPENMODELICAHOME must be set in order to find the mingw compilers which
rem are assumed to be in %OPENMODELICAHOME%\MinGW\bin

set OLDPATH=%PATH%
pushd "%OPENMODELICAHOME%\MinGW\bin"
set PATH=%CD%
popd
del ..\mosh\src\options.o *.o *.a
pushd ..\mosh\src
g++ -O3 -c options.cpp
popd
mingw32-make
del ..\mosh\src\options.o *.o
set PATH=%OLDPATH%
