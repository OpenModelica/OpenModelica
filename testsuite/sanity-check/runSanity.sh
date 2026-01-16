#!/usr/bin/env bash

# Bash "strict mode"
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TESTSUITE_DIR="$(realpath "$SCRIPT_DIR/..")"
RTEST="$TESTSUITE_DIR/rtest"

usage() {
  cat <<EOF
Usage: $0 --omc=/full/path/to/omc [--workdir=/path/to/workdir] [--testCpp=true|false] [--help]

Options:
  --omc   Full path to the omc executable. REQUIRED.
  --workdir     Working directory where to perform the sanity test. Default: current directory
  --testCpp     true or false. If true, run the Cpp simCodeTarget tests. Default: false
  -h, --help    Show this help and exit
EOF
}

# Defaults
OMC=""
WORKDIR="$(pwd)"
TEST_CPP="false"

# Parse args (supports --opt value and --opt=value)
while [ "$#" -gt 0 ]; do
  case "$1" in
    --omc=*) OMC="${1#*=}"; shift;;
    --omc) OMC="$2"; shift 2;;
    --workdir=*) WORKDIR="${1#*=}"; shift;;
    --workdir) WORKDIR="$2"; shift 2;;
    --testCpp=*) TEST_CPP="${1#*=}"; shift;;
    --testCpp) TEST_CPP="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown argument: $1"; usage; exit 1;;
  esac
done

# Normalize testCpp
case "${TEST_CPP,,}" in
  true|1|yes) TEST_CPP="true";;
  *) TEST_CPP="false";;
esac

# Normalize omc
if [ -z "$OMC" ]; then
  echo "Error: --omc is required."
  usage
  exit 1
fi
OMC="$(realpath "$OMC")"

echo "Using omc: $OMC ($("$OMC" --version))"
echo "Working directory: $WORKDIR"
echo "testCpp: $TEST_CPP"

echo Check that omc can be started and a model can be build for NF OF with runtimes C Cpp FMU

echo Unset OPENMODELICALIBRARY to make sure the default is used
unset OPENMODELICALIBRARY

mkdir -p "$WORKDIR/.sanity-check"
pushd "$WORKDIR/.sanity-check" >/dev/null
cp "$SCRIPT_DIR/testSanity.mos" .

# Run sanity MOS script
echo Running sanity MOS script
"$OMC" --linearizationDumpLanguage=matlab testSanity.mos
./M
./M -l=1.0
ls linearized_model.m
ls M.fmu
rm -rf ./M* ./OMCppM* ./linear_M* ./linearized_model.m

# Test optional Cpp simCode target
if [ "$TEST_CPP" = "true" ]; then
  "$OMC" --simCodeTarget=Cpp testSanity.mos
  ./M
  ls M.fmu
  rm -rf ./M* ./OMCppM*
fi
popd >/dev/null
rm -rf "$WORKDIR/.sanity-check"

# Additional tests from testsuite
echo Testing some models from testsuite, ffi, meta
cd "$TESTSUITE_DIR/flattening/libraries/biochem"
"$RTEST" --return-with-error-code EnzMM.mos

cd "$TESTSUITE_DIR/flattening/modelica/ffi"
"$RTEST" --return-with-error-code ModelicaInternal_countLines.mos
"$RTEST" --return-with-error-code Integer1.mos

cd "$TESTSUITE_DIR/metamodelica/meta"
"$RTEST" --return-with-error-code AlgPatternm.mos
