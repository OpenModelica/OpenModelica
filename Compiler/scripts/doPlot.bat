@echo off
set OMPTII=%OPENMODELICAHOME%\share\omc\java\ptplot.jar
start javaw -classpath %OMPTII% ptolemy.plot.plotml.EditablePlotMLApplication %1