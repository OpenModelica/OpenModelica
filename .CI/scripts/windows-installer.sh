#!/bin/bash
# Make the Windows installer of an OpenModelica install tree, on Linux or
# Windows: <out>.exe with NSIS 3, <out>.msi with wixl (msitools). The version
# is `git describe` of this checkout.
#
#   windows-installer.sh <tree> <out.exe|out.msi>
#   windows-installer.sh --uninstaller <Uninstall.exe>
#
# The second form writes the uninstaller of the .exe alone, with wine, so that
# it can be signed. UNINSTALLER=<that file> makes the .exe install it.
#
# MAKENSIS and WIXL override the programs to run.

set -eu

if [ "${1:-}" = --uninstaller ] && [ $# -eq 2 ]; then
  tree=
  out=$2
elif [ $# -eq 2 ]; then
  tree=$(cd "$1" && pwd)
  out=$2
else
  echo "usage: $0 <tree> <out.exe|out.msi>" >&2
  echo "       $0 --uninstaller <Uninstall.exe>" >&2
  exit 2
fi

installer=$(cd "$(dirname "$0")/../installer" && pwd)
out=$(cd "$(dirname "$out")" && pwd)/$(basename "$out")
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
run_makensis() {
  "$MAKENSIS" -V2 -INPUTCHARSET UTF8 \
    -DOMVERSION="$version" -DPRODUCTVERSION="$product" $nightly "$@" \
    "$installer/OpenModelica.nsi"
}
if [ -z "$tree" ]; then
  printf '!macro %s\n!macroend\n' OM_INSTALL_FILES OM_DOC_SHORTCUTS > "$work/files.nsh"
  run_makensis -DUNINSTALLER_ONLY -DFILES="$work/files.nsh" -DOUTFILE="$work/writer.exe"
  # Debian and Ubuntu keep wineserver off PATH.
  wineserver=$(command -v wineserver || ls /usr/lib/*/wine/wineserver | head -1)
  export WINEPREFIX=$work/wine WINEDEBUG=-all WINEDLLOVERRIDES='mscoree,mshtml='
  wineboot --init >/dev/null 2>&1
  "$wineserver" -w
  wine "$work/writer.exe"
  "$wineserver" -w
  mv "$work/Uninstall.exe" "$out"
else
  case "$out" in
    *.msi)
      python3 "$installer/msi.py" "$tree" "$work/OpenModelica.wxs" "$version"
      "$WIXL" -a x64 -o "$out" "$work/OpenModelica.wxs"
      ;;
    *)
      python3 "$installer/files.py" "$tree" "$work/files.nsh"
      uninstaller=${UNINSTALLER:+$(cd "$(dirname "$UNINSTALLER")" && pwd)/$(basename "$UNINSTALLER")}
      run_makensis -DFILES="$work/files.nsh" -DOUTFILE="$out" ${uninstaller:+"-DUNINSTALLER=$uninstaller"}
      ;;
  esac
fi
ls -l "$out"
