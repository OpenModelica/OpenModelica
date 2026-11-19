#!/usr/bin/env bash
#
# Build OpenModelica with OMDev (MSYS2 UCRT64) and run the whole testsuite on
# Windows. This is what the Jenkins job Windows/OM_Win runs, see
# .CI/Jenkinsfile.OM_Win; it used to be typed into the configuration of that job.
#
# Run from an OMDev login shell (MSYSTEM=UCRT64), from any directory:
#   bash .CI/scripts/om-win-testsuite.sh
#
# It expects a clean source tree (no build_cmake/ and no build/): a build tree
# kept from an earlier revision can fail to configure, and the testsuite must
# never run with the omc such a build leaves behind.
#
# Exit code: 0 when the testsuite ran, also when tests failed (those are in
# testsuite/partest/result.xml); not 0 when the configuration, the build or the
# testsuite driver itself failed.

set -uo pipefail

SOURCE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/../.." &> /dev/null && pwd )
# The timings of the earlier runs, which runtests.pl uses to order the tests.
RUNTESTDB="${RUNTESTDB:-/c/dev}"
THREADS="${NUMBER_OF_PROCESSORS:-$(nproc)}"

# The login shell replaces TMP and TEMP with its own /tmp. Clean up what earlier
# runs left there and go back to the Windows directories.
if [ -n "${ORIGINAL_TMP:-}" ] && [ -n "${ORIGINAL_TEMP:-}" ]; then
  T1=$(cygpath "$ORIGINAL_TMP")
  T2=$(cygpath "$ORIGINAL_TEMP")
  rm -rf "$T1"/cc* "$T2"/cc*
  if [ -n "${TMP:-}" ]; then
    find "$TMP"/*/ ! -name '*omc-rtest*' -exec rm -rf {} + 2> /dev/null
  fi
  export TMP="$T1" TEMP="$T2"
fi
echo "TMP: ${TMP:-} TEMP: ${TEMP:-}"

export PATH="/c/Program Files/TortoiseSVN/bin:/c/bin/jdk/bin:/c/bin/nsis:$PATH:/c/bin/git/bin:/c/Program Files/Microsoft/jdk-21.0.1.12-hotspot/bin:/c/Program Files/Git/bin"
if [ -n "${OMDEV:-}" ]; then
  OMDEV=$(cygpath -u "$OMDEV")
  export OMDEV
fi

# omc and the tests want Windows paths here.
OPENMODELICAHOME="$(cygpath -w "$SOURCE_DIR")\\build"
OPENMODELICALIBRARY="$OPENMODELICAHOME\\lib\\omlibrary"
export OPENMODELICAHOME OPENMODELICALIBRARY

cd "$SOURCE_DIR" || exit 1

# From here to the testsuite the first command that fails ends the script.
set -ex
trap 'echo "om-win-testsuite.sh: command failed, exit code $?"' ERR

cmake --version
cmake -S . -B build_cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release -DOM_USE_CCACHE=OFF -DCMAKE_INSTALL_PREFIX=build
cmake --build build_cmake --parallel "$THREADS" --target install
cmake --build build_cmake --parallel "$THREADS" --target testsuite-depends
build/bin/omc --version

# The generated Compile.bat calls mingw32-make; use the make of MSYS2 instead.
sed -i.bak 's/mingw32-make/..\\..\\usr\\bin\\make/g' build/share/omc/scripts/Compile.bat

cp -f "$RUNTESTDB"/runtest.db.* testsuite/ || true

cd testsuite/partest
trap - ERR
set +e
time perl ./runtests.pl -nocolour -with-xml
CODE=$?
set -e

# 0: all tests passed, 7: some tests failed. Anything else: the run is broken.
if [ "$CODE" = 0 ] || [ "$CODE" = 7 ]; then
  cp -f ../runtest.db.* "$RUNTESTDB"/
  exit 0
fi
echo "om-win-testsuite.sh: runtests.pl failed, exit code $CODE"
exit "$CODE"
