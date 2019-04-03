@echo off
cls

rem get path to omc
SET OMC=%OPENMODELICAHOME%\bin\omc.exe +simCodeTarget=Cpp +locale=C +running-testsuite=dummy.out

rem try to simulate all *.mos files in current folder
for %%f in (*.mos) do (

time /t
echo %%f
%OMC% %%f > %%f.txt 2>&1
rem check the output
if %ERRORLEVEL% NEQ 0 (
 	echo - translation failed
) else (
 	if not exist %%~nf_res.mat (
 		echo - simulation failed
 	) else (
 		echo - OK
 	)
)

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
)

rem sortresults
python sortResults.py > results.txt
