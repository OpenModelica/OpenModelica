#!/bin/bash
set -e

# If number of arguments less then 1; print usage and exit
if [ $# -lt 1 ]; then
    printf "Usage: $0 <test_file>\n"
    exit 1
fi

testexe="$1" # The test executable name.

echo "Running testcase "$testexe
ORIGINAL_TEMP=$TEMP
ORIGINAL_TMP=$TMP
ORIGINAL_TMPDIR=$TMPDIR
NEW_TEMP=$OMEditTestResults/$testexe
NEW_TMP=$OMEditTestResults/$testexe
NEW_TMPDIR=$OMEditTestResults/$testexe
export TEMP=$NEW_TEMP
export TMP=$NEW_TMP
export TMPDIR=$NEW_TMPDIR
$testexe || $testexe || $testexe || $testexe || $testexe
export TEMP=$ORIGINAL_TEMP
export TMP=$ORIGINAL_TMP
export TMPDIR=$ORIGINAL_TMPDIR
