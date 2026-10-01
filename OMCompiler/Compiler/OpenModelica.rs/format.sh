#!/usr/bin/env bash
# Format every Rust and TOML file of the omc port that git tracks or would
# track (new files count, ignored and generated ones do not), or with --check
# only report what is not formatted (that is what CI runs, see
# .github/workflows/rust-format.yml). Covers both cargo workspaces:
# OMCompiler/Compiler/OpenModelica.rs and OMCompiler/SimulationRuntime/rust.
# Run from anywhere inside the checkout.
#
#   format.sh            # rewrite files in place
#   format.sh --check    # exit 1 and print a diff if anything is unformatted
#
# Why not `cargo fmt`: it needs `cargo metadata`, and the compiler workspace
# does not load on a clean checkout (the lib.rs files mmtorust generates are
# missing, see README.md). rustfmt runs on the files directly instead, with
# skip_children so `mod` declarations of generated modules are not followed.
# Generated sources are not in git and are not touched here; mmtorust and susan
# format them as they write them (mmtorust/src/rustfmt.rs).
#
# Tools: rustfmt of the toolchain pinned in rust-toolchain.toml, and taplo
# (`cargo install taplo-cli --locked`, or a release binary from
# https://github.com/tamasfe/taplo/releases). Override with RUSTFMT=/TAPLO=.
set -euo pipefail

check=0
case "${1-}" in
  --check) check=1 ;;
  "") ;;
  *)
    echo "usage: $0 [--check]" >&2
    exit 2
    ;;
esac

root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
cd "$root"
compiler=OMCompiler/Compiler/OpenModelica.rs
simrt=OMCompiler/SimulationRuntime/rust
RUSTFMT=${RUSTFMT:-rustfmt}
TAPLO=${TAPLO:-taplo}
# The pinned nightly, without the cranelift/wasm components rust-toolchain.toml
# would make rustup install: formatting only needs rustfmt.
RUSTUP_TOOLCHAIN=${RUSTUP_TOOLCHAIN:-$(sed -n 's/^channel *= *"\(.*\)"/\1/p' $compiler/rust-toolchain.toml)}
export RUSTUP_TOOLCHAIN

for tool in "$RUSTFMT" "$TAPLO"; do
  if ! command -v "$tool" > /dev/null; then
    echo "error: $tool not found (see the header of $0 for how to install it)" >&2
    exit 2
  fi
done

status=0

# rustfmt finds the rustfmt.toml of the workspace a file belongs to; there is
# one per workspace root, and both must say the same.
if ! cmp -s $compiler/rustfmt.toml $simrt/rustfmt.toml; then
  echo "error: $compiler/rustfmt.toml and $simrt/rustfmt.toml differ" >&2
  status=1
fi

rustfmt_args=(--config skip_children=true --unstable-features)
taplo_args=()
if [ $check = 1 ]; then
  rustfmt_args+=(--check)
  taplo_args+=(--check --diff)
fi

if ! git ls-files -z --cached --others --exclude-standard -- "$compiler/*.rs" "$simrt/*.rs" | xargs -0 "$RUSTFMT" "${rustfmt_args[@]}"; then
  status=1
fi
# taplo reads .taplo.toml from the repository root (the current directory).
if ! git ls-files -z --cached --others --exclude-standard -- "$compiler/*.toml" "$simrt/*.toml" | RUST_LOG=warn xargs -0 "$TAPLO" fmt "${taplo_args[@]}"; then
  status=1
fi

if [ $check = 1 ] && [ $status != 0 ]; then
  echo "Formatting check failed. Run $compiler/format.sh and commit the result." >&2
fi
exit $status
