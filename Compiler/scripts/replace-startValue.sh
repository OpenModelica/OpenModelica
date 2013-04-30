#!/bin/sh
#usage: ./replace-startValue.sh variableName variableStartValue Model_init.xml

# test if it exists where we put it in Windows
XSLTPROCEXE="${OPENMODELICAHOME}/lib/omc/libexec/xsltproc/xsltproc.exe"
if [ ! -f "${XSLTPROCEXE}" ]
then
  XSLTPROCEXE=xsltproc
fi
${XSLTPROCEXE} --stringparam variableName $1 --stringparam variableStart $2 "${OPENMODELICAHOME}/share/omc/scripts/replace-startValue.xsl" $3

