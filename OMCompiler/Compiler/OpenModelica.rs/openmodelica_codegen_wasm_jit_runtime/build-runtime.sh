#!/bin/bash
# Recompile the static wasm-jit linear-memory runtime and refresh the embedded
# `openmodelica_codegen_wasm_jit/src/runtime.wasm`. Run this whenever the runtime
# crate (this directory) changes. Requires the wasm32 target:
#   rustup target add wasm32-unknown-unknown
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"
cargo build --release --target wasm32-unknown-unknown
out="target/wasm32-unknown-unknown/release/openmodelica_codegen_wasm_jit_runtime.wasm"
dest="$here/../openmodelica_codegen_wasm_jit/src/runtime.wasm"
cp "$out" "$dest"
echo "wrote $dest ($(wc -c < "$dest") bytes)"
