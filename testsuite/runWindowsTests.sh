#!/usr/bin/env bash
#
# Run the handful of tests we run on Windows (see testsuite/windows.tests).
#
# The full testsuite is far too slow on Windows to run per pull request, so the
# Windows CI job runs this smoke set instead. It only needs an installed omc:
# rtest finds it in build/ or build_cmake/install_cmake/ beside the testsuite.
#
# Also runnable by hand, on Windows and on Linux:
#   bash testsuite/runWindowsTests.sh
#   bash testsuite/runWindowsTests.sh --list=my.tests

set -uo pipefail

TESTSUITE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIST="${TESTSUITE_DIR}/windows.tests"
MAKE="${MAKE:-make}"

usage() {
  cat <<USAGE
Usage: $0 [--list=FILE] [--help]

Options:
  --list      File listing the tests to run, one path per line, relative to the
              testsuite root. '#' starts a comment. Default: windows.tests
  -h, --help  Show this help and exit
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --list=*) LIST="${1#*=}"; shift;;
    --list) [ -n "${2:-}" ] || { echo "Error: --list requires a value" >&2; exit 1; }; LIST="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Error: unknown argument '$1'" >&2; usage >&2; exit 1;;
  esac
done

[ -f "${LIST}" ] || { echo "Error: no such test list: ${LIST}" >&2; exit 1; }

# FFITestLib is a build artifact of the testsuite, not of omc, and the FFI tests
# in the list look for it by the name the loader uses. It is what the CMake
# 'ffi-test-lib' target builds; the Windows job does not build testsuite-depends,
# so build it here.
echo "== Building FFITestLib"
"${MAKE}" -C "${TESTSUITE_DIR}/flattening/modelica/ffi/FFITest/Resources/BuildProjects/gcc" ||
  { echo "Error: could not build FFITestLib" >&2; exit 1; }

failed=()
total=0

# Default IFS trims the whitespace around the path; anything after it, a
# trailing comment included, lands in the ignored second field.
while read -r test_path _; do
  case "${test_path}" in ''|\#*) continue;; esac

  if [ ! -f "${TESTSUITE_DIR}/${test_path}" ]; then
    echo "Error: ${LIST}: no such test: ${test_path}" >&2
    exit 1
  fi

  total=$((total + 1))
  echo "== ${test_path}"
  ( cd "${TESTSUITE_DIR}/$(dirname "${test_path}")" &&
    "${TESTSUITE_DIR}/rtest" --return-with-error-code "$(basename "${test_path}")" ) ||
    failed+=("${test_path}")
done < "${LIST}"

echo
if [ ${#failed[@]} -eq 0 ]; then
  echo "== ${total} out of ${total} tests passed"
  exit 0
fi

echo "== ${#failed[@]} out of ${total} tests failed:"
printf '  %s\n' "${failed[@]}"
exit 1
