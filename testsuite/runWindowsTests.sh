#!/usr/bin/env bash
#
# Run the smoke set of tests we run on Windows.
#
# The full testsuite is far too slow on Windows to run per pull request, so the
# Windows CI job runs this smoke set instead: enough to catch a broken
# toolchain, a missing DLL or a path handling bug, not to check compiler
# semantics, which the Linux runs already cover.
#
# A test is in the smoke set when its header says '// suite: smoke'. The suite is
# enabled by default, so these tests also run as part of the whole testsuite.
#
# It only needs an installed omc: rtest finds it in build/ or
# build_cmake/install_cmake/ beside the testsuite.
#
# Also runnable by hand, on Windows and on Linux:
#   bash testsuite/runWindowsTests.sh
#
# --wine runs the set on Linux against an omc cross-compiled for MSVC, under
# wine, with the tools in testsuite/wine standing in for nmake, cl and cmake.

set -uo pipefail

TESTSUITE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
MAKE="${MAKE:-make}"

usage() {
  cat <<USAGE
Usage: $0 [--wine] [-jN] [--help]

Runs every *.mos test under testsuite/ tagged '// suite: smoke' in its header.

  --wine  run an MSVC omc (bin/omc.exe) under wine
  -jN     run N tests at a time (default 1)
USAGE
}

wine=
jobs=1
while [ "$#" -gt 0 ]; do
  case "$1" in
    --wine) wine=1;;
    -j[0-9]*) jobs=${1#-j};;
    -h|--help) usage; exit 0;;
    *) echo "Error: unknown argument '$1'" >&2; usage >&2; exit 1;;
  esac
  shift
done

# The install tree rtest picks, a wine prefix whose system32 has the Windows
# side of testsuite/wine, and FFITestLib as a DLL.
setup_wine() {
  local wine_dir="${TESTSUITE_DIR}/wine" omhome= d t
  for d in build/install_cmake build_cmake/install_cmake build; do
    if [ -e "${TESTSUITE_DIR}/../${d}/bin/omc.exe" ]; then
      omhome="${TESTSUITE_DIR}/../${d}"
      break
    fi
  done
  if [ -z "${omhome}" ]; then
    echo "Error: found no bin/omc.exe to run under wine" >&2
    return 1
  fi
  if [ ! -x "${omhome}/bin/omc-diff" ]; then
    echo "Error: rtest needs a Linux ${omhome}/bin/omc-diff" >&2
    return 1
  fi
  cp "${wine_dir}/omc" "${omhome}/bin/omc" || return 1

  export WINEPREFIX="${WINEPREFIX:-${wine_dir}/prefix}"
  export WINEDEBUG="${WINEDEBUG:--all}"
  export OMC_TOOLCHAIN=clang-cl
  # rtest points HOME elsewhere, so settle the xwin sysroot now.
  for d in "${XWIN_CACHE_DIR:-}" "${XWIN_CACHE_DIR:-}/xwin" "${CARGO_HOME:-}/xwin" \
           "${HOME}/.cache/cargo-xwin/xwin"; do
    if [ -d "${d}/crt/include" ]; then
      export XWIN_CACHE_DIR="${d}"
      break
    fi
  done
  # Otherwise wine complains on stderr, which ends up in every test's output.
  if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
    export XDG_RUNTIME_DIR="${WINEPREFIX}/xdg-runtime"
    mkdir -p -m 700 "${XDG_RUNTIME_DIR}"
  fi
  echo "== Setting up the wine prefix ${WINEPREFIX}"
  wineboot -i || return 1

  # What a setup_command compiles for the platform of omc with, against the
  # same C runtime as the generated code.
  export OMC_NATIVE_CC="${wine_dir}/xwin-clang-cl"
  export OMC_NATIVE_CFLAGS="/MD"

  # unzip and sed are what a test's system() finds in MSYS on Windows.
  local system32="${WINEPREFIX}/drive_c/windows/system32"
  for t in "nmake:${wine_dir}/nmake" "cl:${wine_dir}/xwin-clang-cl" "cmake:${wine_dir}/cmake" \
           "unzip:$(command -v unzip)" "sed:$(command -v sed)"; do
    "${wine_dir}/xwin-clang-cl" /nologo /O2 "/DUNIX_PROGRAM=\"${t#*:}\"" \
      "${wine_dir}/unix-shim.c" "/Fo${system32}/" "/Fe${system32}/${t%%:*}.exe" \
      /link shell32.lib || return 1
  done
  rm -f "${system32}/unix-shim.obj"

  echo "== Building FFITestLib"
  local ffi="${TESTSUITE_DIR}/flattening/modelica/ffi/FFITest/Resources"
  mkdir -p "${ffi}/Library/win64" || return 1
  ( cd "${ffi}/Library/win64" &&
    "${wine_dir}/xwin-clang-cl" /nologo /O2 /MD /EHs /LD ../../C-Sources/FFITestLib.c \
      ../../C-Sources/FFITestLibCpp.cpp /FeFFITestLib.dll /link \
      $(grep -ohE '\b[A-Za-z0-9_]+_ext\(' ../../C-Sources/* | sort -u | sed 's/^/\/EXPORT:/; s/($//') &&
    rm -f ./*.obj ) ||
    { echo "Error: could not build FFITestLib" >&2; return 1; }
}

# FFITestLib is a build artifact of the testsuite, not of omc, and the FFI tests
# in the smoke set look for it by the name the loader uses. It is what the CMake
# 'ffi-test-lib' target builds; the Windows job does not build testsuite-depends,
# so build it here.
if [ "${wine}" ]; then
  setup_wine || exit 1
else
  echo "== Building FFITestLib"
  "${MAKE}" -C "${TESTSUITE_DIR}/flattening/modelica/ffi/FFITest/Resources/BuildProjects/gcc" ||
    { echo "Error: could not build FFITestLib" >&2; exit 1; }
fi

echo "== Finding the tests in suite smoke"
list=$(mktemp)
trap 'rm -f "${list}"' EXIT
grep -rlE '^//[ \\|]*suite:.*\bsmoke\b' --include='*.mos' "${TESTSUITE_DIR}" |
  sed "s#^${TESTSUITE_DIR}/#./#" | sort > "${list}"
if [ ! -s "${list}" ]; then
  echo "Error: no test is in suite smoke" >&2
  exit 1
fi

cd "${TESTSUITE_DIR}/partest" &&
  perl ./runtests.pl -nocolour -j"${jobs}" -file="${list}"
status=$?
if [ "${status}" -ne 0 ]; then
  while read -r test_path; do
    log="${TESTSUITE_DIR}/${test_path}.fail_log"
    if [ -f "${log}" ]; then
      echo
      echo "== ${test_path}"
      cat "${log}"
    fi
  done < "${list}"
fi
exit "${status}"
