#!/bin/bash
# Simulate, and export an FMU of, a model whose tables link ModelicaMatIO and
# so HDF5, with an unpacked Linux distribution, then check that both results
# load. Meant for a machine other than the build host: a bare container of
# another distribution with nothing but clang, make and cmake installed, where a
# build-host path on a generated link line fails the link.
#
#   linux-tarball-check.sh <install-tree>
set -euo pipefail

TREE=$(readlink -f "${1:?usage: linux-tarball-check.sh <install-tree>}")
MODEL=ModelicaTest.Tables.CombiTable1Ds.Test1
WORK=$(mktemp -d)
export HOME=$WORK/home
mkdir -p "$HOME"
cd "$WORK"

cat > check.mos <<EOF
ok := installPackage(ModelicaTest, "4.1.0+maint.om", exactMatch=true); getErrorString();
if not ok then exit(1); end if;
ok := loadModel(ModelicaTest, {"4.1.0+maint.om"}); getErrorString();
if not ok then exit(1); end if;
simulate($MODEL); getErrorString();
buildModelFMU($MODEL, version="2.0", fmuType="me", fileNamePrefix="Test1"); getErrorString();
EOF
"$TREE/bin/omc" check.mos
for f in "${MODEL}_res.mat" Test1.fmu; do
  if [ ! -f "$f" ]; then
    echo "ERROR: $f was not produced" >&2
    exit 1
  fi
done

fail=0
check_links() {
  local out
  out=$(ldd "$1")
  echo "$1:"
  echo "$out"
  if grep -q 'not found' <<<"$out"; then
    echo "ERROR: $1 has unresolved libraries" >&2
    fail=1
  fi
  # ModelicaMatIO was compiled against the tree's HDF5, so any other one is a
  # different version that only happens to share the name.
  if grep 'libhdf5' <<<"$out" | grep -v -q -F "$TREE/"; then
    echo "ERROR: $1 takes HDF5 from outside the tree" >&2
    fail=1
  fi
}

check_links "$WORK/$MODEL"

mkdir fmu
(cd fmu && cmake -E tar xf ../Test1.fmu)
cat > dlcheck.c <<'EOF'
#include <dlfcn.h>
#include <stdio.h>
int main(int argc, char **argv) {
  void *h = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
  if (!h) { fprintf(stderr, "%s\n", dlerror()); return 1; }
  const char *(*version)(void) = (const char *(*)(void))dlsym(h, "fmi2GetVersion");
  if (!version) { fprintf(stderr, "%s\n", dlerror()); return 1; }
  printf("%s: fmi2GetVersion() = %s\n", argv[1], version());
  return 0;
}
EOF
clang -o dlcheck dlcheck.c -ldl
shopt -s nullglob
fmu_libs=(fmu/binaries/*/*.so)
if [ ${#fmu_libs[@]} = 0 ]; then
  echo "ERROR: Test1.fmu has no shared library" >&2
  exit 1
fi
for so in "${fmu_libs[@]}"; do
  check_links "$WORK/$so"
  ./dlcheck "$WORK/$so" || fail=1
done

exit $fail
