#!/bin/bash
# Try a Windows installer (.exe or .msi) under wine: install it silently,
# simulate a model with the installed omc, uninstall it, and check that
# everything it installed and registered is gone again. An MSI is installed with
# all its features.
#
#   windows-installer-check.sh <installer.exe|installer.msi>

set -eu

if [ $# -ne 1 ]; then
  echo "usage: $0 <installer.exe|installer.msi>" >&2
  exit 2
fi

exe=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
# Debian and Ubuntu keep wineserver off PATH.
wineserver=$(command -v wineserver || ls /usr/lib/*/wine/wineserver 2>/dev/null | head -1)
if [ -z "$wineserver" ]; then
  echo "ERROR: wineserver not found" >&2
  exit 1
fi
WINEPREFIX=$(mktemp -d)
export WINEPREFIX WINEDEBUG=-all WINEDLLOVERRIDES='mscoree,mshtml='
trap '"$wineserver" -k 2>/dev/null || true; rm -rf "$WINEPREFIX"' EXIT
wineboot --init >/dev/null 2>&1
"$wineserver" -w

om='C:\OpenModelica'
dir=$WINEPREFIX/drive_c/OpenModelica
env='HKLM\System\CurrentControlSet\Control\Session Manager\Environment'
uninstall='HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall'
# wine puts the shortcuts of a per-machine MSI into the user's start menu.
menus=("$WINEPREFIX/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs"
       "$WINEPREFIX"/drive_c/users/*/AppData/Roaming/Microsoft/Windows/"Start Menu"/Programs)

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

case "$exe" in
  *.msi)
    wine msiexec /i "$exe" /qn ADDLOCAL=ALL "INSTALLDIR=$om\\"
    installed=(bin/omc.exe)
    ;;
  *)
    wine "$exe" /S "/D=$om"
    installed=(bin/omc.exe uninstall.log Uninstall.exe)
    ;;
esac
"$wineserver" -w
for f in "${installed[@]}"; do
  test -f "$dir/$f" || fail "$f was not installed"
done
wine reg query "$env" /v OPENMODELICAHOME 2>/dev/null | grep -q -F "$om" ||
  fail "OPENMODELICAHOME does not point to $om"
wine reg query "$uninstall" /s 2>/dev/null | grep -q 'DisplayName.*OpenModelica ' ||
  fail "the installation is not registered in $uninstall"
find "${menus[@]}" -name 'OpenModelica Connection Editor.lnk' 2>/dev/null | grep -q . ||
  fail "no start menu shortcut for OMEdit"

work=$WINEPREFIX/drive_c/check
mkdir "$work"
cat > "$work/check.mos" <<'EOF'
loadString("model M Real x(start = 1, fixed = true); equation der(x) = -x; end M;"); getErrorString();
simulate(M, stopTime = 1); getErrorString();
EOF
(cd "$work" && timeout 600 wine "$dir/bin/omc.exe" --simCodeTarget=wasm-jit check.mos) | tee "$work/check.log"
grep -q 'The simulation finished successfully' "$work/check.log" && test -s "$work/M_res.mat" ||
  fail "the installed omc did not simulate M"

case "$exe" in
  *.msi)
    wine msiexec /x "$exe" /qn
    ;;
  *)
    # _? runs the uninstaller in place and waits for it; it cannot delete itself then.
    wine "$dir/Uninstall.exe" /S "_?=$om"
    "$wineserver" -w
    rm -f "$dir/Uninstall.exe"
    ;;
esac
"$wineserver" -w
left=$(find "$dir" -mindepth 1 2>/dev/null | head -20)
[ -z "$left" ] || fail "the uninstaller left files behind:
$left"
if wine reg query "$env" /v OPENMODELICAHOME >/dev/null 2>&1; then
  fail "the uninstaller left OPENMODELICAHOME behind"
fi
if wine reg query "$uninstall" /s 2>/dev/null | grep -q 'DisplayName.*OpenModelica '; then
  fail "the uninstaller left its key in $uninstall behind"
fi
if [ -n "$(find "${menus[@]}" -path '*OpenModelica*' 2>/dev/null)" ]; then
  fail "the uninstaller left start menu entries behind"
fi
echo "installer check passed"
