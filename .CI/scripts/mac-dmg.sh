#!/bin/bash
# Wrap a macOS .app in a compressed .dmg from Linux, where there is no hdiutil:
# `xorrisofs -hfsplus` writes the HFS+ filesystem, libdmg-hfsplus' `dmg`
# compresses it. Both are in the rust-qt-mac build-deps image.
#
#   mac-dmg.sh <app> <out.dmg> [volume-name]

set -eu

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "usage: $0 <app> <out.dmg> [volume-name]" >&2
  exit 2
fi

app=$1
out=$2
vol=${3:-OpenModelica}

XORRISOFS=${XORRISOFS:-$(command -v xorrisofs || true)}
DMG=${DMG:-$(command -v dmg || true)}
for tool in "$XORRISOFS" "$DMG"; do
  if [ -z "$tool" ]; then
    echo "ERROR: xorrisofs and dmg (libdmg-hfsplus) are both needed" >&2
    exit 1
  fi
done

if [ ! -d "$app" ]; then
  echo "ERROR: '$app' is not an .app directory" >&2
  exit 1
fi

stage=$(dirname "$out")/.dmg-stage.$$
iso=$(dirname "$out")/.dmg-stage.$$.iso
trap 'rm -rf "$stage" "$iso"' EXIT
rm -rf "$stage"
mkdir -p "$stage"

# Hardlinks where the filesystem allows: the bundle is over a gigabyte.
cp -al "$app" "$stage/" 2> /dev/null || cp -a "$app" "$stage/"
ln -s /Applications "$stage/Applications"  # drag-to-install

"$XORRISOFS" -hfsplus -V "$vol" -D -l -no-pad -r -dir-mode 0755 -o "$iso" "$stage"
rm -f "$out"
"$DMG" "$iso" "$out"

if [ ! -s "$out" ]; then
  echo "ERROR: $out was not written" >&2
  exit 1
fi
ls -l "$out"
