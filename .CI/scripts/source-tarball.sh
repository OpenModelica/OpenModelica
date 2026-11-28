#!/bin/bash
# Make a source tarball of this checkout and its submodules that builds without
# network access. Besides the sources it carries
#   cargo-vendor/       the crates of every cargo workspace, and of the std
#                       library the wasm builds compile (-Zbuild-std)
#   cargo-vendor.toml   the source replacement for them (cmake/omc_cargo_vendor.cmake)
#   downloads/          what the configure step downloads (OM_DOWNLOADS_DIR)
#   doc/UsersGuide/prebuilt/  the User's Guide, installed as is (doc/CMakeLists.txt)
#   the MUMPS sources, where moo's Ipopt.cmake looks before it downloads them
# The testsuites are left out.
#
#   source-tarball.sh <out.tar.xz> <downloads-dir> [<doc-tree>]
#
# <doc-tree> is an install tree with share/doc/OpenModelica/UsersGuide in it.
# cargo must be the one rust-toolchain.toml pins, with its rust-src component.

set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "usage: $0 <out.tar.xz> <downloads-dir> [<doc-tree>]" >&2
  exit 2
fi

src=$(cd "$(dirname "$0")/../.." && pwd)
out=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
downloads=$(cd "$2" && pwd)
doc=${3:+$(cd "$3" && pwd)}

describe=$(git -C "$src" describe --match 'v*.*' --always)
name=openmodelica-${describe#v}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
root=$work/$name

# The committed sources, which a configure in the checkout cannot have changed.
git -C "$src" archive --prefix="$name/" HEAD | tar -C "$work" -xf -
git -C "$src" submodule --quiet foreach --recursive \
  "git archive --prefix=\"$name/\$displaypath/\" HEAD | tar -C \"$work\" -xf -"
rm -rf "$root/testsuite" "$root/OMSimulator/testsuite"

# The version, which a tree without .git cannot describe.
echo "$describe" > "$root/OMVERSION.txt"
git -C "$src/OMSimulator" describe --tags --abbrev=7 --match='v*.*' --exclude='*-dev' |
  sed -E 's/(.*)-(.*)-(.*)/\1.post\2-\3/' > "$root/OMSimulator/version.txt"

# The workspaces that mmtorust fills have no targets in the sources. cargo vendor
# only reads the manifests, so an empty src/lib.rs will do while it runs.
rust_roots=(OMCompiler/Compiler/OpenModelica.rs OMCompiler/Compiler/runtime/rust OMCompiler/SimulationRuntime/rust)
stubs=()
while IFS= read -r -d '' manifest; do
  dir=$(dirname "$manifest")
  if [ ! -e "$dir/src/lib.rs" ] && [ ! -e "$dir/src/main.rs" ] &&
     ! grep -q -E '^\[(lib|\[bin\])\]' "$manifest"; then
    mkdir -p "$dir/src"
    touch "$dir/src/lib.rs"
    stubs+=("$dir/src/lib.rs")
  fi
done < <(find "${rust_roots[@]/#/$root/}" -name Cargo.toml -print0)

# Every workspace has a Cargo.lock. The first root's is the main one, and its
# rust-toolchain.toml selects the cargo that runs.
workspaces=()
while IFS= read -r -d '' lock; do
  workspaces+=(-s "$(dirname "$lock")/Cargo.toml")
done < <(find "${rust_roots[@]/#/$root/}" -name Cargo.lock ! -path "$root/${rust_roots[0]}/Cargo.lock" -print0 | sort -z)
cd "$root/${rust_roots[0]}"
sysroot=$(rustc --print sysroot)
cargo vendor --locked --manifest-path Cargo.toml "${workspaces[@]}" \
  -s "$sysroot/lib/rustlib/src/rust/library/Cargo.toml" \
  "$root/cargo-vendor" > "$work/cargo-vendor.toml"
cd "$work"
sed "s|directory = \"$root/cargo-vendor\"|directory = \"cargo-vendor\"|" "$work/cargo-vendor.toml" > "$root/cargo-vendor.toml"
grep -q '^directory = "cargo-vendor"$' "$root/cargo-vendor.toml"
for stub in "${stubs[@]}"; do
  rm "$stub"
  rmdir --ignore-fail-on-non-empty "$(dirname "$stub")"
done

cp -a "$downloads" "$root/downloads"
find "$root/downloads" -name '*.part-*' -delete

ipopt=$root/OMCompiler/3rdParty/moo/third-party/Ipopt.cmake/ThirdParty
mumps_version=$(sed -n -E 's/^ *set\(MUMPS_VERSION "(.*)"\)/\1/p' "$ipopt/CMakeLists.txt")
mumps_url=$(sed -n -E 's/^ *set\(MUMPS_URL "(.*)"\)/\1/p' "$ipopt/CMakeLists.txt")
mumps_url=${mumps_url//'${MUMPS_VERSION}'/$mumps_version}
mkdir -p "$ipopt/MUMPS/sources"
curl -fsSL --retry 3 "$mumps_url" | tar -C "$ipopt/MUMPS/sources" --strip-components=1 -xzf -

if [ -n "$doc" ]; then
  cp -a "$doc/share/doc/OpenModelica/UsersGuide" "$root/doc/UsersGuide/prebuilt"
fi

rm -f "$out"
tar -C "$work" --owner=0 --group=0 --sort=name -cf - "$name" | xz -T0 -6 > "$out"
ls -l "$out"
