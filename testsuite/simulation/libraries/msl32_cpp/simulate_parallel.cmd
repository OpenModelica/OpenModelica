@echo off
rem runs the test %2
rem %2 is mos file and %1 is number of tmp directory %3 are additional options to omc

mkdir ..\tmp%1 2>nul
mkdir ..\tmp%1\ReferenceFiles 2>nul
del ..\tmp%1\*.* /Q
del ..\tmp%1\ReferenceFiles\*.* /Q
copy %2 ..\tmp%1
copy ReferenceFiles\%~n2.mat ..\tmp%1\ReferenceFiles
cd ..\tmp%1
echo 1 > running

rem get path to omc
SET OMC=%OPENMODELICAHOME%\bin\omc.exe +locale=C +running-testsuite=dummy.out

%OMC% %2 %3 > ..\msl32_cpp\%2.txt 2>&1

del running
cd ..\msl32_cpp

exit