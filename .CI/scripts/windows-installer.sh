#!/bin/bash
# Make the Windows installer of an OpenModelica install tree, on Linux or
# Windows: <out>.exe with NSIS 3, <out>.msi with wixl (msitools). The version
# is `git describe` of this checkout.
#
#   windows-installer.sh <tree> <out.exe|out.msi>
#
# MAKENSIS and WIXL override the programs to run.

set -eu

if [ $# -ne 2 ]; then
  echo "usage: $0 <tree> <out.exe|out.msi>" >&2
  exit 2
fi

installer=$(cd "$(dirname "$0")/../installer" && pwd)
tree=$(cd "$1" && pwd)
out=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
MAKENSIS=${MAKENSIS:-makensis}
WIXL=${WIXL:-wixl}

describe=$(git -C "$installer" describe --match 'v*.*' --always)
tag=$(git -C "$installer" describe --match 'v*.*' --always --abbrev=0)
version=${describe#v}
tag=${tag#v}
case "$tag" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "ERROR: no v<major>.<minor>.<patch> tag in the history of $installer: '$tag'" >&2; exit 1 ;;
esac
# VIProductVersion takes four numbers.
product=${tag%%-*}.0
nightly=
if [ "$version" != "$tag" ]; then
  nightly=-DOMNIGHTLY=1
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
rm -f "$out"
case "$out" in
  *.msi)
    python3 "$installer/msi.py" "$tree" "$work/OpenModelica.wxs" "$version"
    "$WIXL" -a x64 -o "$out" "$work/OpenModelica.wxs"
    ;;
  *)
    python3 "$installer/files.py" "$tree" "$work/files.nsh"
    "$MAKENSIS" -V2 -INPUTCHARSET UTF8 \
      -DOMVERSION="$version" -DPRODUCTVERSION="$product" $nightly \
      -DFILES="$work/files.nsh" -DOUTFILE="$out" \
      "$installer/OpenModelica.nsi"
    ;;
esac
ls -l "$out"
