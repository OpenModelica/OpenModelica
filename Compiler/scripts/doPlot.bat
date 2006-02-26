@echo off
if defined PTII goto runplot
set PTII=%OPENMODELICAHOME%\bin\ptplot.jar
:runplot  
start javaw -classpath %PTII% ptolemy.plot.plotml.EditablePlotMLApplication %1

