#!/bin/bash
# Merge two single-architecture macOS install trees into one universal tree:
# every Mach-O file both trees have becomes a fat binary, everything else is
# taken from the first tree. Used by the macOS nightly, which cross-compiles
# x86_64 and arm64 in separate Jenkins stages (see .CI/Jenkinsfile.rust-nightly).
#
#   mac-universal.sh <out-tree> <tree-a> <tree-b>
#
# `lipo` is LLVM's on a Linux host; override with $LIPO.

set -eu

if [ $# -ne 3 ]; then
  echo "usage: $0 <out-tree> <tree-a> <tree-b>" >&2
  exit 2
fi

out=$1
a=$2
b=$3

if [ -z "${LIPO:-}" ]; then
  for c in llvm-lipo lipo; do
    if command -v "$c" > /dev/null 2>&1; then LIPO=$c; break; fi
  done
fi
# Some distributions ship it only under a version suffix; take the newest.
if [ -z "${LIPO:-}" ]; then
  LIPO=$(ls /usr/bin/llvm-lipo-* 2> /dev/null | sort -V | tail -1)
fi
if [ -z "${LIPO:-}" ]; then
  echo "ERROR: no lipo found; install llvm or set \$LIPO" >&2
  exit 1
fi

for t in "$a" "$b"; do
  if [ ! -d "$t" ]; then
    echo "ERROR: '$t' is not a directory" >&2
    exit 1
  fi
done

# What lipo can merge: 64-bit Mach-O (little-endian, both architectures), an
# already-fat file, and a static archive of Mach-O members (`!<arch>\n`, which
# every lib/omc/*.a is -- a generated simulation links them, so they have to
# carry both architectures too).
is_lipoable() {
  case "$(od -An -tx1 -N8 "$1" | tr -d ' \n')" in
    cffaedfe* | cefaedfe* | cafebabe*) return 0 ;;
    213c617263683e0a) return 0 ;;
    *) return 1 ;;
  esac
}

rm -rf "$out"
mkdir -p "$out"

fat=0
copied=0
onlya=0
onlyb=0
differ=0

# Directories and symlinks first, so a link is never shadowed by a copy.
(cd "$a" && find . -type d -print0) | while IFS= read -r -d '' d; do
  mkdir -p "$out/$d"
done
(cd "$a" && find . -type l -print0) | while IFS= read -r -d '' l; do
  mkdir -p "$out/$(dirname "$l")"
  cp -P "$a/$l" "$out/$l"
done

# The counters live in a file: the loop below runs in a subshell (a pipe), so
# plain shell variables would not survive it.
counts=$(mktemp)
trap 'rm -f "$counts"' EXIT
printf '0 0 0 0 0\n' > "$counts"
bump() { # bump <field-index>
  awk -v i="$1" '{ $i = $i + 1; print }' "$counts" > "$counts.new"
  mv "$counts.new" "$counts"
}

(cd "$a" && find . -type f -print0) | while IFS= read -r -d '' f; do
  mkdir -p "$out/$(dirname "$f")"
  if [ ! -e "$b/$f" ]; then
    echo "only in $a: $f" >&2
    cp -p "$a/$f" "$out/$f"
    bump 3
    continue
  fi
  # An archive lipo refuses is one whose members are not Mach-O -- the wasm
  # sysroot under lib/wasm32-wasi is full of them -- and those are the same file
  # in both trees anyway, so let the copy below handle it.
  if is_lipoable "$a/$f" && "$LIPO" -create "$a/$f" "$b/$f" -output "$out/$f" 2> /dev/null; then
    chmod --reference="$a/$f" "$out/$f"
    bump 1
    continue
  fi
  # Not machine code. The two builds should have produced the same bytes; when
  # they did not it is a build that embedded its architecture somewhere it is
  # not supposed to, so say which file rather than silently picking one.
  if ! cmp -s "$a/$f" "$b/$f"; then
    echo "WARNING: differs between the two architectures, taking $a's: $f" >&2
    bump 5
  fi
  cp -p "$a/$f" "$out/$f"
  bump 2
done

(cd "$b" && find . -type f -print0) | while IFS= read -r -d '' f; do
  if [ ! -e "$a/$f" ]; then
    echo "only in $b: $f" >&2
    mkdir -p "$out/$(dirname "$f")"
    cp -p "$b/$f" "$out/$f"
    bump 4
  fi
done

read -r fat copied onlya onlyb differ < "$counts"
echo "universal tree $out: ${fat} fat, ${copied} copied, ${onlya} only in $a, ${onlyb} only in $b, ${differ} differing"

# A tree with no fat binary means the inputs were not two macOS builds.
if [ "$fat" = 0 ]; then
  echo "ERROR: no Mach-O file was merged; are '$a' and '$b' macOS install trees?" >&2
  exit 1
fi
