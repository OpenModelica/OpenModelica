#!/bin/bash
# Fold a unix-style macOS install tree into a self-contained OMEdit.app.
#
#   mac-app-bundle.sh <install-tree> <out.app> [qt-macos-prefix]
#
# <install-tree> is the merged tree the omc and GUI stages install into, including
# the Applications/OMEdit.app CMake builds (which holds only the OMEdit binary).
#
#   Contents/MacOS/        the executables
#   Contents/Frameworks/   the dylibs, where dyld and codesign expect Mach-O
#   Contents/Resources/    lib/<triple>/omc, share/, include/ -- what omc resolves
#                          as OPENMODELICAHOME (see Settings::bundle_home)

set -eu

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "usage: $0 <install-tree> <out.app> [qt-macos-prefix]" >&2
  exit 2
fi

tree=$1
out=$2
qt=${3:-${QT_MACOS_PREFIX:-}}

# LLVM's, on a Linux host; macOS spells them without the prefix.
otool=$(command -v llvm-otool || ls /usr/bin/llvm-otool-* 2>/dev/null | sort -V | tail -1 || command -v otool)
if [ -z "${otool:-}" ]; then
  echo "ERROR: no otool/llvm-otool found; it reads the dependency list" >&2
  exit 1
fi

if [ ! -d "$tree" ]; then
  echo "ERROR: '$tree' is not a directory" >&2
  exit 1
fi

src_app=$tree/Applications/OMEdit.app
if [ ! -d "$src_app" ]; then
  echo "ERROR: $src_app is missing; build the GUI clients for macOS first" >&2
  exit 1
fi

rm -rf "$out"
mkdir -p "$out/Contents/MacOS" "$out/Contents/Frameworks" "$out/Contents/Resources"

# What CMake's bundle already has: Info.plist, the OMEdit binary, its icon.
cp -a "$src_app/Contents/." "$out/Contents/"

# The command-line tools (omc, OMSimulator, the other clients) alongside OMEdit.
if [ -d "$tree/bin" ]; then
  find "$tree/bin" -maxdepth 1 -type f -perm -u+x -exec cp -a {} "$out/Contents/MacOS/" \;
fi

# The data prefix. `lib` keeps its <triple>/omc shape: omc builds those paths from
# OPENMODELICAHOME, and a simulation's dlopen has to find them there.
for d in lib share include; do
  if [ -d "$tree/$d" ]; then
    mkdir -p "$out/Contents/Resources/$d"
    cp -a "$tree/$d/." "$out/Contents/Resources/$d/"
  fi
done

# To Frameworks, which the launchers carry an `@loader_path/../Frameworks` rpath
# for. Everything the generated code dlopens by path stays where it is.
found=0
for lib in "$out"/Contents/Resources/lib/*/omc/libOpenModelicaCompiler.dylib; do
  [ -e "$lib" ] || continue
  mv "$lib" "$out/Contents/Frameworks/"
  found=1
done
if [ "$found" -eq 0 ]; then
  echo "ERROR: no libOpenModelicaCompiler.dylib under $tree/lib/*/omc" >&2
  exit 1
fi

# ── Qt, and anything else reached through @rpath ─────────────────────────────
#
# macdeployqt is a macOS binary, so walk LC_LOAD_DYLIB ourselves -- the Mach-O
# counterpart of .cmake/windows-qt-deploy.cmake. Everything is linked as
# `@rpath/...`, and CMAKE_INSTALL_RPATH already points into Contents/Frameworks,
# so copying each dependency there is enough.

# `@rpath/QtCore.framework/Versions/A/QtCore` -> `QtCore.framework`, or a plain
# `@rpath/libfoo.dylib` -> `libfoo.dylib`. Anything absolute is the system's.
# Every Mach-O in the bundle. The dlopened plugins and QML modules are in nobody's
# link list but carry @rpath dependencies of their own.
bundle_macho() {
  find "$out/Contents/MacOS" "$out/Contents/Frameworks" \
       "$out/Contents/PlugIns" "$out/Contents/Resources/qml" \
       -type f \( -perm -u+x -o -name '*.dylib' \) 2>/dev/null
}

rpath_deps() {
  "$otool" -L "$1" 2>/dev/null | tail -n +2 | awk '{print $1}' | sed -n 's|^@rpath/||p'
}

search_dirs="$out/Contents/Frameworks $out/Contents/Resources/lib/*/omc"
[ -n "$qt" ] && search_dirs="$search_dirs $qt/lib"

find_dep() {
  for dir in $search_dirs; do
    [ -e "$dir/$1" ] && { echo "$dir/$1"; return 0; }
  done
  return 1
}

deploy() {
  queue=$(bundle_macho)
  seen=""
  while [ -n "$queue" ]; do
    next=""
    for bin in $queue; do
      for dep in $(rpath_deps "$bin"); do
        top=${dep%%/*}                       # Foo.framework, or libfoo.dylib
        case " $seen " in *" $top "*) continue ;; esac
        seen="$seen $top"
        [ -e "$out/Contents/Frameworks/$top" ] && continue
        if src=$(find_dep "$top"); then
          case "$top" in
            *.framework)
              # Preserved, not dereferenced: a framework *is* its Versions/A plus
              # the Current/top-level symlinks, and dyld and codesign both expect
              # to find it in that shape.
              cp -a "$src" "$out/Contents/Frameworks/$top" ;;
            *)
              # Dereferenced: a plain dylib is usually a symlink to a versioned
              # file (libomqwt.6.dylib -> libomqwt.6.1.5.dylib) that nothing links
              # by name, so preserving the link would leave it dangling.
              cp -aL "$src" "$out/Contents/Frameworks/$top" ;;
          esac
          # Headers and the static-link metadata are build-time only.
          rm -rf "$out/Contents/Frameworks/$top/Headers" \
                 "$out/Contents/Frameworks/$top/Versions/A/Headers"
          find "$out/Contents/Frameworks/$top" -name '*.prl' -delete 2>/dev/null || true
          next="$next $out/Contents/Frameworks/$top/$(basename "$top" .framework)"
        else
          echo "WARNING: no source for @rpath/$top (give the Qt prefix?)" >&2
        fi
      done
    done
    queue=$(for f in $next; do [ -f "$f" ] && echo "$f"; done)
  done
}

# ── Qt plugins and QML ───────────────────────────────────────────────────────
#
# Nothing links these -- Qt dlopens them by path -- so the dependency walk cannot
# see them, and without the platform plugin QGuiApplication calls qFatal(). Same
# selection as the Windows cross deploy (OMEdit/OMEditGUI/CMakeLists.txt).
install_name_tool=$(command -v llvm-install-name-tool ||
  ls /usr/bin/llvm-install-name-tool-* 2>/dev/null | sort -V | tail -1 ||
  command -v install_name_tool)

copy_plugin() { # copy_plugin <category>/<file>
  src=$qt/plugins/$1
  [ -f "$src" ] || return 0
  mkdir -p "$out/Contents/PlugIns/$(dirname "$1")"
  cp -a "$src" "$out/Contents/PlugIns/$1"
  # Qt ships them pointing at the kit (`@loader_path/../../lib`).
  if [ -n "${install_name_tool:-}" ]; then
    "$install_name_tool" -add_rpath @loader_path/../../Frameworks \
      "$out/Contents/PlugIns/$1" 2>/dev/null || true
  fi
}

if [ -n "$qt" ]; then
  for plugin in platforms/libqcocoa.dylib styles/libqmacstyle.dylib \
                imageformats/libqjpeg.dylib imageformats/libqsvg.dylib \
                imageformats/libqico.dylib imageformats/libqgif.dylib \
                iconengines/libqsvgicon.dylib \
                tls/libqsecuretransportbackend.dylib \
                networkinformation/libqapplenetworkinformation.dylib; do
    copy_plugin "$plugin"
  done

  # QML, as the Windows deploy does it. Module directories only.
  scanner=$(ls "$QT_HOST_PATH/libexec/qmlimportscanner" \
               "${qt%/macos}"/gcc_64/libexec/qmlimportscanner 2>/dev/null | head -1)
  animqml=$(dirname "$0")/../../OMEdit/OMEditGUI/wasm/qml
  if [ -n "${scanner:-}" ] && [ -d "$qt/qml" ] && [ -d "$animqml" ]; then
    "$scanner" -rootPath "$animqml" -importPath "$qt/qml" 2> /dev/null |
      sed -n 's/.*"relativePath"[^"]*"\([^"]*\)".*/\1/p' | sort -u |
      while read -r m; do
        [ -d "$qt/qml/$m" ] || continue
        mkdir -p "$out/Contents/Resources/qml/$m"
        find "$qt/qml/$m" -maxdepth 1 -type f ! -name '*_debug.dylib' \
          -exec cp -a {} "$out/Contents/Resources/qml/$m/" \;
        for lib in "$out/Contents/Resources/qml/$m"/*.dylib; do
          [ -e "$lib" ] || continue
          [ -n "${install_name_tool:-}" ] &&
            "$install_name_tool" -add_rpath \
              "@loader_path/$(echo "$m" | sed 's|[^/]*|..|g')/../../Frameworks" \
              "$lib" 2>/dev/null || true
        done
      done
  else
    echo "WARNING: no qmlimportscanner or Qt qml dir; the 3D animation view will not load" >&2
  fi

  # What macdeployqt writes; paths relative to Contents/.
  printf '[Paths]\nPlugins = PlugIns\nImports = Resources/qml\nQml2Imports = Resources/qml\n' \
    > "$out/Contents/Resources/qt.conf"
fi

deploy

# QtWebEngineProcess is nested inside QtWebEngineCore.framework and loads it
# through rpaths that assume the Qt kit, so it dies at launch inside a bundle.
# Five levels up from its MacOS directory is Contents/Frameworks.
helper=$out/Contents/Frameworks/QtWebEngineCore.framework/Helpers/QtWebEngineProcess.app/Contents/MacOS/QtWebEngineProcess
if [ -f "$helper" ] && [ -n "${install_name_tool:-}" ]; then
  "$install_name_tool" -add_rpath @executable_path/../../../../.. "$helper" 2>/dev/null || true
fi

# Every @rpath dependency must resolve inside the bundle, or it only runs on a
# machine with the same Qt installed -- invisible until someone else opens it.
missing=0
for bin in $(bundle_macho); do
  for dep in $(rpath_deps "$bin"); do
    top=${dep%%/*}
    if [ ! -e "$out/Contents/Frameworks/$top" ]; then
      echo "UNRESOLVED: $top (needed by ${bin#$out/})" >&2
      missing=$((missing + 1))
    fi
  done
done
if [ "$missing" -ne 0 ]; then
  echo "ERROR: $missing unresolved @rpath dependencies; the bundle is not self-contained" >&2
  exit 1
fi

echo "bundle: $out"
du -sh "$out"
