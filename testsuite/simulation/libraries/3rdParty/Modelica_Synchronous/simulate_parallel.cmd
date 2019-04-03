@echo off
rem runs the test %2
rem %2 is mos file and %1 is number of tmp directory %3 are additional options to omc

mkdir ..\tmp%1 2>nul
mkdir ..\tmp%1\ReferenceFiles 2>nul
del ..\tmp%1\*.* /Q
del ..\tmp%1\ReferenceFiles\*.* /Q
copy %2 ..\tmp%1
copy ReferenceFiles\%~n2.mat ..\tmp%1\ReferenceFiles
if exist common.mos copy common.mos ..\tmp%1
cd ..\tmp%1
echo 1 > running

rem get path to omc
SET OMC=%OPENMODELICAHOME%\bin\omc.exe +simCodeTarget=Cpp +locale=C +running-testsuite=dummy.out

%OMC% %2 %3 > ..\Modelica_Synchronous\%2.txt 2>&1

del running
cd ..\Modelica_Synchronous

exit