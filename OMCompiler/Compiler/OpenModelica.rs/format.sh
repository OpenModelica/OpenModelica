#!/usr/bin/env bash
# Format the Rust and TOML files of the omc port with rustfmt and taplo. Covers
# both cargo workspaces: OMCompiler/Compiler/OpenModelica.rs and
# OMCompiler/SimulationRuntime/rust. Anything else it is given is ignored, so
# callers can pass every file of a commit or pull request.
#
#   format.sh FILE...           # rewrite the given files in place
#   format.sh --check FILE...   # exit 1 and print a diff if one is unformatted
#   format.sh --staged          # format what is staged for commit, in the index
#                               # and in the working tree (common/pre-commit.sh)
#   format.sh [--check] --all   # every file git tracks or would track
#
# The rules are only enforced for files that are added or changed, so the tree
# is formatted file by file as it is worked on. Do not commit the result of
# --all.
#
# Why not `cargo fmt`: it needs `cargo metadata`, and the compiler workspace
# does not load on a clean checkout (the lib.rs files mmtorust generates are
# missing, see README.md). rustfmt runs on the files directly instead, with
# skip_children so `mod` declarations are not followed into other files.
#
# Tools: rustfmt of the toolchain pinned in rust-toolchain.toml, and taplo
# (`cargo install taplo-cli --locked`, or a release binary from
# https://github.com/tamasfe/taplo/releases). Override with RUSTFMT=/TAPLO=.
set -euo pipefail

usage() {
  echo "usage: $0 [--check] FILE... | --staged | [--check] --all" >&2
  exit 2
}

check=0
mode=files
while [ $# -gt 0 ]; do
  case "$1" in
    --check) check=1 ;;
    --staged) mode=staged ;;
    --all) mode=all ;;
    --) shift; break ;;
    -*) usage ;;
    *) break ;;
  esac
  shift
done
if [ $mode = files ] && [ $# = 0 ]; then usage; fi
if [ $mode != files ] && [ $# != 0 ]; then usage; fi
if [ $mode = staged ] && [ $check = 1 ]; then usage; fi

compiler=OMCompiler/Compiler/OpenModelica.rs
simrt=OMCompiler/SimulationRuntime/rust
RUSTFMT=${RUSTFMT:-rustfmt}
TAPLO=${TAPLO:-taplo}

# Paths relative to the repository root, NUL-separated.
list_files() {
  case $mode in
    files) git ls-files -z --full-name --cached --others --exclude-standard -- "$@" ;;
    staged) git diff -z --cached --name-only --diff-filter=ACMR ;;
    all) git -C "$(git rev-parse --show-toplevel)" ls-files -z --cached --others --exclude-standard -- $compiler $simrt ;;
  esac
}

rs=()
toml=()
while IFS= read -r -d '' f; do
  case "$f" in
    "$compiler"/*.rs | "$simrt"/*.rs) rs+=("$f") ;;
    "$compiler"/*.toml | "$simrt"/*.toml) toml+=("$f") ;;
  esac
done < <(list_files "$@")

cd "$(git rev-parse --show-toplevel)"
# The pinned nightly, without the cranelift/wasm components rust-toolchain.toml
# would make rustup install: formatting only needs rustfmt.
RUSTUP_TOOLCHAIN=${RUSTUP_TOOLCHAIN:-$(sed -n 's/^channel *= *"\(.*\)"/\1/p' $compiler/rust-toolchain.toml)}
export RUSTUP_TOOLCHAIN

# A missing tool fails the run, except in the pre-commit hook. The hook never
# blocks a commit: files it cannot format (missing tool, syntax error) are left
# as they are, and CI reports them if they need formatting.
have() {
  if "$1" --version > /dev/null 2>&1; then return 0; fi
  if [ $mode = staged ]; then
    echo "warning: $1 not found, $2 files are committed unformatted ($compiler/README.md has the setup)" >&2
    return 1
  fi
  echo "error: $1 not found (see the header of $0 for how to install it)" >&2
  exit 2
}
if [ ${#rs[@]} != 0 ] && ! have "$RUSTFMT" Rust; then rs=(); fi
if [ ${#toml[@]} != 0 ] && ! have "$TAPLO" TOML; then toml=(); fi

status=0

# rustfmt finds the rustfmt.toml of the workspace a file belongs to; there is
# one per workspace root, and both must say the same.
if ! cmp -s $compiler/rustfmt.toml $simrt/rustfmt.toml; then
  echo "error: $compiler/rustfmt.toml and $simrt/rustfmt.toml differ" >&2
  status=1
fi

# Formats file $1 from stdin to stdout. rustfmt looks for rustfmt.toml from the
# current directory, taplo for .taplo.toml (the repository root).
format_stdin() {
  case "$1" in
    *.rs) (cd "$(dirname "$1")" && "$RUSTFMT" --emit stdout) ;;
    *) RUST_LOG=error "$TAPLO" fmt --stdin-filepath "$1" - ;;
  esac
}

if [ $mode = staged ]; then
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  for f in ${rs[@]+"${rs[@]}"} ${toml[@]+"${toml[@]}"}; do
    read -r filemode old _ < <(git ls-files --stage -- "$f")
    # The index and the working tree are formatted separately, so changes that
    # are not staged stay out of the commit.
    if ! git cat-file blob "$old" | format_stdin "$f" > "$tmp"; then
      echo "warning: could not format $f, it is committed as it is" >&2
      continue
    fi
    new=$(git hash-object -w --path "$f" "$tmp")
    if [ "$new" = "$old" ]; then continue; fi
    git update-index --cacheinfo "$filemode,$new,$f"
    if [ -f "$f" ] && format_stdin "$f" < "$f" > "$tmp" 2> /dev/null; then
      cat "$tmp" > "$f"
    fi
    echo "Formatted $f"
  done
  exit $status
fi

rustfmt_args=(--config skip_children=true --unstable-features)
taplo_args=()
if [ $check = 1 ]; then
  rustfmt_args+=(--check)
  taplo_args+=(--check --diff)
fi

# Files given by name may be gone (deleted in the pull request).
existing() {
  local f
  for f in "$@"; do
    if [ -f "$f" ]; then printf '%s\0' "$f"; fi
  done
}

if ! existing ${rs[@]+"${rs[@]}"} | xargs -0 -r "$RUSTFMT" "${rustfmt_args[@]}"; then
  status=1
fi
if ! existing ${toml[@]+"${toml[@]}"} | RUST_LOG=warn xargs -0 -r "$TAPLO" fmt ${taplo_args[@]+"${taplo_args[@]}"}; then
  status=1
fi

if [ $check = 1 ] && [ $status != 0 ]; then
  echo "Formatting check failed. Run $compiler/format.sh on the files above and commit the result." >&2
fi
exit $status
