#!/bin/bash
# usage: fix-tests.sh /path/to/file/containing/broken/tests.txt [extra runtests.pl flags]
# should be run from trunk/testsuite
# created by Martin Sjölund
#
# Tests marked '// suite: disabled' are skipped, pass -suites=+disabled to
# baseline those as well.

FILE=`realpath $1`
CD=`pwd`
echo Started in directory: $CD
if test -z "$OPENMODELICAHOME"; then
  cd `pwd`/testsuite/partest/
else
  cd $OPENMODELICAHOME/../testsuite/partest/
fi
echo Switched to directory: $(pwd)
echo Baselining files from $FILE in parallel ...
perl ./runtests.pl -b -file=$FILE $2
cd $CD

