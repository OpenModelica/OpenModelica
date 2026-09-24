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

# The test executables live in the build tree, and so does the
# libOpenModelicaCompiler their RUNPATH points at. omc derives its installation
# directory from the path of that library (OPENMODELICAHOME is not consulted),
# so from the build tree it would look for the runtime headers and libraries
# next to it and fail to compile any simulation. When OPENMODELICAHOME names an
# installation, load its libraries instead (LD_LIBRARY_PATH takes precedence
# over RUNPATH), so omc finds itself there.
if [ -n "$OPENMODELICAHOME" ]; then
  for omc_lib_dir in "$OPENMODELICAHOME"/lib/*/omc; do
    if [ -e "$omc_lib_dir/libOpenModelicaCompiler.so" ]; then
      export LD_LIBRARY_PATH="$omc_lib_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
  done
fi

printf "Running testcase '%s' with tmp dir '%s'\n" "$test_exe_path" "$tmp_dir_for_test"
$test_exe_path

# Resotore the old env tmp dirs
export TEMP=$ORIGINAL_TEMP
export TMP=$ORIGINAL_TMP
export TMPDIR=$ORIGINAL_TMPDIR
