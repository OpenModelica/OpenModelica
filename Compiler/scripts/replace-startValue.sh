#!/bin/sh
#usage: replacestartValue variableName variableStartValue Model_init.xml
${OPENMODELICAHOME}/lib/omc/libexec/xsltproc/xsltproc.exe --stringparam variableName $1 --stringparam variableStart $2 replace-startValue.xsl $3
