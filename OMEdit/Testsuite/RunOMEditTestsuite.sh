#!/bin/bash
set -e

testcases=( "BrowseMSL" "Diagram" "Transformation" "Homotopy" )
OMEditTestResults="$PWD/OMEditTestResult"

for i in "${testcases[@]}"
do
  echo "Running testcase "$i
  ORIGINAL_TEMP=$TMP
  ORIGINAL_TMP=$TMP
  ORIGINAL_TMPDIR=$TMPDIR
  NEW_TEMP=$OMEditTestResults/$i
  NEW_TMP=$OMEditTestResults/$i
  NEW_TMPDIR=$OMEditTestResults/$i
  export TEMP=$NEW_TEMP
  export TMP=$NEW_TMP
  export TMPDIR=$NEW_TMPDIR
  ./$i || ./$i || ./$i || ./$i || ./$i
  export TEMP=$ORIGINAL_TEMP
  export TMP=$ORIGINAL_TMP
  export TMPDIR=$ORIGINAL_TMPDIR
done
rm -rf $OMEditTestResults
