#!/bin/bash
set -e

testcases=( "BrowseMSL" "Diagram" "Transformation" "Homotopy" "Expression"
            "ModelInstance" "VariableValue" "Utilities" "StringHandler" "DynamicAnnotation"
            "AutoCompletion" )
OMEditTestResults="$PWD/OMEditTestResult"

for testcase in "${testcases[@]}"
do
  # Try 5 times if it does not pass
  ./RunOMEditTest.sh ./$testcase $OMEditTestResults \
  || ./RunOMEditTest.sh ./$testcase $OMEditTestResults \
  || ./RunOMEditTest.sh ./$testcase $OMEditTestResults \
  || ./RunOMEditTest.sh ./$testcase $OMEditTestResults \
  || ./RunOMEditTest.sh ./$testcase $OMEditTestResults
done
rm -rf $OMEditTestResults
