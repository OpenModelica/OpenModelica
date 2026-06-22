#!/usr/bin/env bash
#
# Build OpenModelica as a wasm library + JavaScript (wasm-bindgen) bindings.
#
#   ./wasm/build.sh [MODE]
#
# MODE is <host>-<profile>:
#   node-debug     node host, debug profile          (default)
#   node-release   node host, release profile
#   web-debug      browser host, debug profile
#   web-release    browser host, release profile     (what we ship)
#
# <host> selects the wasm-bindgen target: `nodejs` (CommonJS, require()) or
# `web` (ES module + async init, for a browser). <profile> selects the cargo
# build profile. Output goes to wasm/pkg-<host>/ so the two hosts don't clobber
# each other.
#
# Requires the wasm32 target and a wasm-bindgen-cli matching the pinned
# wasm-bindgen (0.2.100):
#   rustup target add wasm32-unknown-unknown
#   cargo install wasm-bindgen-cli --version 0.2.100
set -euo pipefail

# wasm-bindgen-cli installs into the cargo bin dir, which isn't always on PATH.
export PATH="${CARGO_HOME:-$HOME/.cargo}/bin:$PATH"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../OpenModelica.rs/wasm
ROOT="$(dirname "$HERE")"                              # .../OpenModelica.rs
cd "$ROOT"

MODE="${1:-node-debug}"
case "$MODE" in
  node-debug)   HOST=nodejs; PROFILE=debug   ;;
  node-release) HOST=nodejs; PROFILE=release ;;
  web-debug)    HOST=web;    PROFILE=debug   ;;
  web-release)  HOST=web;    PROFILE=release ;;
  *)
    echo "usage: $0 [node-debug|node-release|web-debug|web-release]" >&2
    exit 1
    ;;
esac

TARGET=wasm32-unknown-unknown
CRATE=libopenmodelica_compiler
WASM_NAME=OpenModelicaCompiler
OUTDIR="$HERE/pkg-$HOST"

# wasmtime has no wasm backend, so the wasm-jit engine must be wasmer (`js`).
COMMON=(--target "$TARGET" -p "$CRATE" --no-default-features --features engine-wasmer)

if [ "$PROFILE" = debug ]; then
  # The workspace dev profile selects the cranelift *rustc* backend (fast native
  # builds); it cannot target wasm32, so force LLVM for codegen here.
  cargo build "${COMMON[@]}" --config 'profile.dev.codegen-backend="llvm"'
  WASM="target/$TARGET/debug/$WASM_NAME.wasm"
else
  cargo build --release "${COMMON[@]}"
  WASM="target/$TARGET/release/$WASM_NAME.wasm"
fi

echo "==> wasm-bindgen ($MODE, target=$HOST) -> $OUTDIR"
rm -rf "$OUTDIR"
wasm-bindgen "$WASM" --out-dir "$OUTDIR" --target "$HOST"

# Optional size optimisation for release if wasm-opt (binaryen) is available.
if [ "$PROFILE" = release ] && command -v wasm-opt >/dev/null 2>&1; then
  echo "==> wasm-opt -Oz"
  wasm-opt -Oz "$OUTDIR/${WASM_NAME}_bg.wasm" -o "$OUTDIR/${WASM_NAME}_bg.wasm"
fi

echo "==> built ($MODE):"
ls -la "$OUTDIR"
if [ "$HOST" = nodejs ]; then
  echo "Try:  node wasm/omc-cli.js 'getVersion()'   or   node wasm/omc-cli.js  (REPL)"
else
  echo "Try:  python3 -m http.server -d wasm 8000   then open http://localhost:8000/"
fi
