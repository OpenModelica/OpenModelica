@echo off
REM usage: .\replace-startValue.bat variableName variableStartValue Model_init.xml

set XSLTPROCEXE="%OPENMODELICAHOME%\lib\omc\libexec\xsltproc\xsltproc.exe"
%XSLTPROCEXE% --stringparam variableName %1 --stringparam variableStart %2 "%OPENMODELICAHOME%\share\omc\scripts\replace-startValue.xsl" %3

