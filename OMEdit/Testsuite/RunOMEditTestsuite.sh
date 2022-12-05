#!/bin/bash
set -e

testcases=( "BrowseMSL" "Diagram" "Transformation" "Homotopy" "Expression" "ModelInstance" )
OMEditTestResults="$PWD/OMEditTestResult"

for testcase in "${testcases[@]}"
do
  ./RunOMEditTest.sh ./$testcase
done
rm -rf $OMEditTestResults
