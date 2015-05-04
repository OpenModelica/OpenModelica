#!/bin/bash
# usage: fix-tests.sh /full/path/to/file/containing/broken/tests.txt
# should be run from trunk/testsuite
# created by Martin Sjölund
if test -z "$OPENMODELICAHOME"; then
  RTEST=`pwd`/rtest
else
  RTEST=$OPENMODELICAHOME/../testsuite/rtest
fi
while read line ; do (if test ! -z "$line"; then cd `dirname $line` && $RTEST -b `basename $line`; fi) ; done < $1
