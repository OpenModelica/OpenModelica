#!/bin/bash
# Make a Linux install tree self-contained: bundle the Qt kit and every other
# non-system shared library the tree resolves outside itself.
#
#   linux-deploy.sh <install-tree> [qt-prefix]
#
# With no qt-prefix the Qt half is skipped and only the libraries are bundled,
# which is what the CLI distribution needs -- it has no GUI clients to deploy.
#
# Works on a cross-built tree too: set TRIPLE to the target's multiarch triple
# (e.g. TRIPLE=aarch64-linux-gnu). Nothing here runs a target binary -- the
# closure is read with readelf and resolved by hand, because ldd cannot load a
# foreign architecture -- and patchelf is architecture-neutral.
#
# No rpath rewriting is needed, which is why the layout is what it is. The tree's
# own binaries already carry RUNPATH $ORIGIN/../lib/<triple>/omc, and Qt's own
# libraries use $ORIGIN, so Qt goes in under a kit-shaped qt/ subdirectory (its
# plugins resolve $ORIGIN/../../lib to qt/lib on their own) and is symlinked into
# the RUNPATH directory for the executables to find. bin/qt.conf points Qt at
# that prefix, which is also how QtWebEngine finds resources/ and locales.
set -euo pipefail

TREE=$(readlink -f "${1:?usage: linux-deploy.sh <install-tree> <qt-prefix>}")
QT=${2:+$(readlink -f "$2")}
TRIPLE=${TRIPLE:-x86_64-linux-gnu}
LIBDIR=$TREE/lib/$TRIPLE/omc
QTOUT=$LIBDIR/qt

# Host-provided, never bundled: the glibc family and the C++ runtime (every
# supported target has them at or above what a 22.04 build asks for), and the
# GL dispatch/driver stack, which has to match the machine's graphics driver.
SYSTEM_LIBS='^(ld-linux.*|libc|libm|libdl|libpthread|librt|libresolv|libnsl|libutil|libcrypt|libmvec|libstdc\+\+|libgcc_s|libGL|libGLX|libGLdispatch|libOpenGL|libEGL|libdrm|libgbm)\.so.*$'

is_system() { [[ $(basename "$1") =~ $SYSTEM_LIBS ]]; }

# `file | grep -q` would do, but grep exiting on the first match SIGPIPEs file,
# and under `set -o pipefail` that reads as "not an ELF" -- silently skipping
# files instead of deploying them.
is_elf() { [ "$(od -An -tx1 -N4 "$1" 2>/dev/null | tr -d ' \n')" = 7f454c46 ]; }

mkdir -p "$LIBDIR"
if [ -n "$QT" ]; then
mkdir -p "$QTOUT/lib" "$QTOUT/plugins" "$QTOUT/libexec"

# Qt plugins OMEdit loads at runtime; they are in no import table, so they seed
# the closure rather than being found by it.
for p in platforms/libqxcb.so platforms/libqminimal.so platforms/libqoffscreen.so \
         xcbglintegrations/libqxcb-glx-integration.so \
         imageformats/libqjpeg.so imageformats/libqsvg.so imageformats/libqgif.so \
         imageformats/libqico.so iconengines/libqsvgicon.so \
         tls/libqopensslbackend.so platforminputcontexts/libqtvirtualkeyboardplugin.so \
         networkinformation/libqnetworkmanager.so sqldrivers/libqsqlite.so; do
  if [ -f "$QT/plugins/$p" ]; then
    mkdir -p "$QTOUT/plugins/$(dirname "$p")"
    cp -a "$QT/plugins/$p" "$QTOUT/plugins/$p"
  fi
done

# Libraries Qt opens by name at runtime, so no import table names them and the
# closure below would never reach them. libxcb-cursor is required by the xcb
# platform plugin from Qt 6.5 on: without it the plugin fails to initialise and
# OMEdit dies before it can even report that it has no display.
for so in libxcb-cursor.so.0; do
  src=""
  for dir in "/usr/lib/$TRIPLE" "/lib/$TRIPLE"; do
    [ -e "$dir/$so" ] && { src=$dir/$so; break; }
  done
  if [ -n "$src" ]; then
    cp -aL "$src" "$LIBDIR/$so"
  else
    echo "WARNING: $so not installed for $TRIPLE; OMEdit will not start" >&2
  fi
done

# QML modules and the QtWebEngine runtime assets.
[ -d "$QT/qml" ] && cp -a "$QT/qml" "$QTOUT/qml"
[ -f "$QT/libexec/QtWebEngineProcess" ] && cp -a "$QT/libexec/QtWebEngineProcess" "$QTOUT/libexec/"
[ -d "$QT/resources" ] && cp -a "$QT/resources" "$QTOUT/resources"
mkdir -p "$QTOUT/translations"
[ -d "$QT/translations/qtwebengine_locales" ] &&
  cp -a "$QT/translations/qtwebengine_locales" "$QTOUT/translations/"
fi

# Where a DT_NEEDED name is looked for, in order: the tree's own directories
# first (so internal links stay internal), then the Qt kit, then the target's
# multiarch directories on the build host.
SEARCH=()
while read -r d; do SEARCH+=("$d"); done < <(find "$TREE/lib" -type d 2>/dev/null)
[ -n "$QT" ] && SEARCH+=("$QT/lib")
SEARCH+=("/usr/lib/$TRIPLE" "/lib/$TRIPLE" "/usr/lib" "/lib")

# Always succeeds: an unresolvable name is not an error (it is a system library
# the target provides), and under `set -e` a failing command substitution would
# take the script down with it.
resolve() {
  local name=$1 dir
  for dir in "${SEARCH[@]}"; do
    if [ -e "$dir/$name" ]; then
      printf '%s\n' "$dir/$name"
      return 0
    fi
  done
  return 0
}

# The closure: walk every ELF in the tree, resolve what it needs, copy anything
# that came from outside, and repeat until nothing new appears.
while :; do
  added=0
  while read -r elf; do
    is_elf "$elf" || continue
    while read -r name; do
      is_system "/$name" && continue
      src=$(resolve "$name")
      [ -n "$src" ] || continue
      case $src in "$TREE"/*) continue ;; esac
      if [ -n "$QT" ] && [[ $src == "$QT"/* ]]; then
        dest=$QTOUT/lib/$name
        link=$LIBDIR/$name
      else
        dest=$LIBDIR/$name
        link=
      fi
      [ -e "$dest" ] && continue
      cp -aL "$src" "$dest"
      # Qt libraries live under qt/lib so their plugins resolve them; the
      # executables find them through their own RUNPATH via this symlink.
      [ -n "$link" ] && ln -sfn "qt/lib/$name" "$link"
      added=1
    done < <(readelf -d "$elf" 2>/dev/null |
             sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p')
  done < <(find "$TREE/bin" "$TREE/lib" -type f 2>/dev/null)
  [ "$added" = 0 ] && break
done

# RUNPATHs. Not every object arrives with one that reaches the others: the Rust
# cdylib is linked without any at all, and DT_RUNPATH is not inherited from the
# executable, so a library it needs is unfindable even sitting beside it. Give
# each directory a RUNPATH reaching both halves of the deployment and the
# question stops depending on who linked what.
# Every ELF in the deployment gets a RUNPATH reaching both halves of it,
# computed from where that file actually sits -- the qml/ tree nests to several
# depths, so a fixed number of ".." segments would be wrong somewhere.
patch_rpath() {
  local dir=$1 f rpath
  rpath='$ORIGIN:$ORIGIN/'$(realpath --relative-to="$dir" "$LIBDIR")
  if [ -n "$QT" ]; then
    rpath=$rpath:'$ORIGIN/'$(realpath --relative-to="$dir" "$QTOUT/lib")
  fi
  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    [ -L "$f" ] && continue
    is_elf "$f" || continue
    patchelf --set-rpath "$rpath" "$f" 2>/dev/null || true
  done
}
while read -r d; do
  patch_rpath "$d"
done < <({ echo "$LIBDIR"; [ -n "$QT" ] && find "$QTOUT" -type d; } | sort -u)

# Simulating a model links the generated code against this very directory:
#   -L<tree>/lib/<triple>/omc ... -llapack -lblas -lgfortran
# and ld will not accept a bare .so.<n>, only the unversioned symlink a -dev
# package ships. Without these three the target needs gfortran and liblapack-dev
# installed to simulate anything; with them it needs neither.
for stem in lapack blas gfortran quadmath; do
  for cand in "$LIBDIR/lib$stem".so.*; do
    [ -e "$cand" ] || continue
    ln -sfn "$(basename "$cand")" "$LIBDIR/lib$stem.so"
    break
  done
done

if [ -n "$QT" ]; then
cat > "$TREE/bin/qt.conf" <<CONF
[Paths]
Prefix = ../lib/$TRIPLE/omc/qt
Libraries = lib
Plugins = plugins
Qml2Imports = qml
LibraryExecutables = libexec
Data = .
Translations = translations
CONF
fi

echo "deployed into $LIBDIR:"
du -sh "$LIBDIR" | sed 's/^/  /'
