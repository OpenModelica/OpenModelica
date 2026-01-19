#!/usr/bin/env bash

set -euo pipefail # bash "strict mode"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

usage() {
  cat <<EOF
Usage: $0 --omc=/full/path/to/omc [--workdir=/path/to/workdir] [--simCodeTarget=C|Cpp] [--help]

Options:
  --omc           Full path to the omc executable. REQUIRED.
  --workdir       Working directory where to perform the sanity test. Default: current directory
  --simCodeTarget Sim code target to use: C or Cpp, default: C
  --clean         true or false. If true, remove temp files. Default: true
  -h, --help      Show this help and exit
EOF
}

# Defaults
OMC=""
WORKDIR="$(pwd)"
SIM_CODE_TARGET="C"
CLEAN="true"

# Parse args (supports --opt value and --opt=value)
while [ "$#" -gt 0 ]; do
  case "$1" in
    --omc=*) OMC="${1#*=}"; shift;;
    --omc) [ -n "${2:-}" ] || { echo "Error: --omc requires a value"; exit 1; }; OMC="$2"; shift 2;;
    --workdir=*) WORKDIR="${1#*=}"; shift;;
    --workdir) [ -n "${2:-}" ] || { echo "Error: --workdir requires a value"; exit 1; }; WORKDIR="$2"; shift 2;;
    --simCodeTarget=*) SIM_CODE_TARGET="${1#*=}"; shift;;
    --simCodeTarget) [ -n "${2:-}" ] || { echo "Error: --simCodeTarget requires a value"; exit 1; }; SIM_CODE_TARGET="$2"; shift 2;;
    --clean=*) CLEAN="${1#*=}"; shift;;
    --clean) [ -n "${2:-}" ] || { echo "Error: --clean requires a value"; exit 1; }; CLEAN="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown argument: $1"; usage; exit 1;;
  esac
done

# Normalize clean
case "${CLEAN,,}" in
  true|1|yes) CLEAN="true";;
  *) CLEAN="false";;
esac

# Normalize simCode target (accepts C or Cpp only)
lc_sim="${SIM_CODE_TARGET,,}"
case "$lc_sim" in
  c) SIM_CODE_TARGET="C";;
  cpp) SIM_CODE_TARGET="Cpp";;
  *) echo "Error: --simCodeTarget must be C or Cpp (got: $SIM_CODE_TARGET)"; usage; exit 1;;
esac

# Normalize omc
if [ -z "$OMC" ]; then
  echo "Error: --omc is required."
  usage
  exit 1
fi
if [ ! -x "$OMC" ]; then
  echo "Error: omc executable not found or not executable: $OMC"
  exit 1
fi
OMC="$(realpath "$OMC")"

echo "Using omc: $OMC ($("$OMC" --version))"
echo "Working directory: $WORKDIR"
echo "simCodeTarget: $SIM_CODE_TARGET"

mkdir -p "$WORKDIR/.sanity-check/$SIM_CODE_TARGET"
pushd "$WORKDIR/.sanity-check/$SIM_CODE_TARGET" >/dev/null
cp "$SCRIPT_DIR/testSanity.mos" .

# Run sanity MOS script with sim Code target
if [ "$SIM_CODE_TARGET" = "Cpp" ]; then
  set -x # echo on
  "$OMC" --simCodeTarget=Cpp testSanity.mos
  ./M
  set +x # echo off
  test -f OMCppM.cpp || { echo "Error: Expected file OMCppM.cpp not found"; exit 1; }
  test -f M.fmu || { echo "Error: Expected file M.fmu not found"; exit 1; }
else
  set -x # echo on
  "$OMC" --linearizationDumpLanguage=matlab testSanity.mos
  ./M
  ./M -l=1.0
  set +x # echo off
  test -f linearized_model.m || { echo "Error: Expected file linearized_model.m not found"; exit 1; }
  test -f M.fmu || { echo "Error: Expected file M.fmu not found"; exit 1; }
fi

# Clean
popd >/dev/null
if [ "$CLEAN" = "true" ]; then
  rm -rf "$WORKDIR/.sanity-check/"
fi

echo "Sanity check ($SIM_CODE_TARGET) passed successfully."
