@echo off
cls
rem script written according to http://superuser.com/questions/232225/multithreaded-windows-for-batch-command

rem try to simulate all *.mos files in current folder
for %%f in (*.mos) do call :loop %%f

rem wait for all processes to finish
call :waitForAllFinished

rem sortresults
python sortResults.py > results.txt

rem finish program
goto :eof


:loop
rem getFreeInstance returns the result in %FreeProcess%, if it is <1, then all are busy
call :getFreeInstance
if %FreeProcess% GEQ 1 (
	rem we have a free process, so start it
	call :simulate %FreeProcess% %1
	goto :eof
)
rem if no free process is available, just wait a second
echo Waiting for instances to close ...
ping -n 2 ::1 >nul 2>&1
rem jump back to see whether we can spawn a new process now
goto loop
goto :eof


:simulate
rem runs the test %2
rem %2 is mos file and %1 is number of tmp directory %3 are additional options to omc
time /t
echo Instance %1: %2

mkdir ..\tmp%1 2>nul
echo 1 > ..\tmp%1\running
start /min simulate_parallel.cmd %1 %2
rem ping, so that there is enough time to create the lock-file
ping -n 2 ::1 >nul 2>&1
goto :eof


:getFreeInstance
for /l %%i in (1,1,%NUMBER_OF_PROCESSORS%) do (
	set FreeProcess=%%i
	if not exist ..\tmp%%i\running goto :eof
)
set FreeProcess=-1
goto :eof


:waitForAllFinished
for /l %%i in (1,1,%NUMBER_OF_PROCESSORS%) do (
	call :waitForFinished %%i
)
goto :eof


:waitForFinished
:finishLoop
	if exist ..\tmp%1\running (
		echo Waiting for process %1 to finish
		ping -n 2 ::1 >nul 2>&1
		goto :finishLoop
	)
goto :eof
