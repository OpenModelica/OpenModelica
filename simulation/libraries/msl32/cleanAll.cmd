@echo off
rem cleanup the mess
del *.exe 2> nul
del *.c 2> nul
del *.h 2> nul
del *.libs 2> nul
del *.makefile 2> nul
del *.csv 2> nul
del *.mat 2>nul
del *.o 2> nul
del *.log 2> nul
del *.xml 2> nul

rem cleanup dymola mess
del buildlog.txt 2> nul
del ds*.txt 2> nul
del dymosim.* 2> nul
