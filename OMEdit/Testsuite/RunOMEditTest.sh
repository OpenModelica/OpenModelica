#!/bin/bash
set -e

# If number of arguments less then 2; print usage and exit
if [ $# -lt 2 ]; then
    printf "Usage: $0 <test_file> <BaseTmpDir>\n"
    exit 1
fi

test_exe_path="$1" # The path to test executable.
tmp_dir_for_testsuite="$2" # The base tmp directory for the test.

test_name=$(basename "$test_exe_path")
tmp_dir_for_test="$tmp_dir_for_testsuite/$test_name"

# Create the tmp dir for the test. If this does not exist OMEdit will try to
# create it. However, if it fails to create it does not report anything and
# that can be confusing.
mkdir -p "$tmp_dir_for_test"

# Save the current env tmp dirs
ORIGINAL_TEMP=$TEMP
ORIGINAL_TMP=$TMP
ORIGINAL_TMPDIR=$TMPDIR

# Export the new tmp dirs for this test.
export TEMP="$tmp_dir_for_test"
export TMP="$tmp_dir_for_test"
export TMPDIR="$tmp_dir_for_test"

printf "Running testcase '%s' with tmp dir '%s'\n" "$test_exe_path" "$tmp_dir_for_test"
$test_exe_path

# Resotore the old env tmp dirs
export TEMP=$ORIGINAL_TEMP
export TMP=$ORIGINAL_TMP
export TMPDIR=$ORIGINAL_TMPDIR
