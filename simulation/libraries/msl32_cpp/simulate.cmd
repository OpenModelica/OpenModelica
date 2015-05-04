@echo off

rem get path to omc
SET OMC=%OPENMODELICAHOME%\bin\omc.exe +locale=C +running-testsuite=dummy.out

%OMC% %1 %2 > %1.txt 2>&1

rem cleanup the mess
del dummy.out
del *.exe 2>nul 1>&2
del *.c 2>nul 1>&2
del *.h 2>nul 1>&2
del *.libs 2>nul 1>&2
del *.makefile 2>nul 1>&2
del *.mat 2>nul 1>&2
del *.o 2>nul 1>&2
del *.log 2>nul 1>&2
del *.xml 2>nul 1>&2


