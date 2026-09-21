#!/usr/bin/env bash
#
# Run the smoke set of tests we run on Windows.
#
# The full testsuite is far too slow on Windows to run per pull request, so the
# Windows CI job runs this smoke set instead: enough to catch a broken
# toolchain, a missing DLL or a path handling bug, not to check compiler
# semantics, which the Linux runs already cover.
#
# There is no separate list of Windows tests to maintain: a test opts in by
# tagging its own header '// win: yes', the same convention OMSimulator's
# testsuite/runtest.py uses for '## win: yes'. This script greps for that tag
# to build the candidate list (grepping thousands of .mos files just to launch
# rtest on ones it would skip anyway is wasted process-spawns); rtest itself
# (--platform=win, see testsuite/rtest) is what actually decides whether a
# matched file runs, so the grep only has to be a fast, cheap superset.
#
# It only needs an installed omc: rtest finds it in build/ or
# build_cmake/install_cmake/ beside the testsuite.
#
# Also runnable by hand, on Windows and on Linux:
#   bash testsuite/runWindowsTests.sh

set -uo pipefail

TESTSUITE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
MAKE="${MAKE:-make}"

usage() {
  cat <<USAGE
Usage: $0 [--help]

Runs every *.mos test under testsuite/ tagged '// win: yes' in its header.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0;;
    *) echo "Error: unknown argument '$1'" >&2; usage >&2; exit 1;;
  esac
done

# FFITestLib is a build artifact of the testsuite, not of omc, and the FFI tests
# tagged below look for it by the name the loader uses. It is what the CMake
# 'ffi-test-lib' target builds; the Windows job does not build testsuite-depends,
# so build it here.
echo "== Building FFITestLib"
"${MAKE}" -C "${TESTSUITE_DIR}/flattening/modelica/ffi/FFITest/Resources/BuildProjects/gcc" ||
  { echo "Error: could not build FFITestLib" >&2; exit 1; }

echo "== Finding tests tagged 'win: yes'"
mapfile -t candidates < <(
  grep -rlE '^//[ \\|]*win:[ \\|]*yes\b' --include='*.mos' "${TESTSUITE_DIR}" |
    sed "s#^${TESTSUITE_DIR}/##" | sort
)

if [ "${#candidates[@]}" -eq 0 ]; then
  echo "Error: no test is tagged 'win: yes'" >&2
  exit 1
fi

failed=()
total=0

for test_path in "${candidates[@]}"; do
  total=$((total + 1))
  echo "== ${test_path}"
  ( cd "${TESTSUITE_DIR}/$(dirname "${test_path}")" &&
    RTEST_PLATFORM=win "${TESTSUITE_DIR}/rtest" --return-with-error-code "$(basename "${test_path}")" ) ||
    failed+=("${test_path}")
done

echo
if [ ${#failed[@]} -eq 0 ]; then
  echo "== ${total} out of ${total} tests passed"
  exit 0
fi

echo "== ${#failed[@]} out of ${total} tests failed:"
printf '  %s\n' "${failed[@]}"
exit 1
