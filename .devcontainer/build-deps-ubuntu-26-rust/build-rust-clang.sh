#!/usr/bin/env bash
#
# Reproduce the Jenkins `cmake-rust-clang` stage locally.
#
# This mirrors common.buildRustOMC() in ../../.CI/common.groovy: same cmake
# flags, same build targets, same order. Run it from inside the
# build-deps-ubuntu-26-rust dev container.
#
# Usage:
#   ./build-rust-clang.sh              # configure + build
#   ./build-rust-clang.sh --clean      # standardSetup() first (DESTRUCTIVE)
#
# Environment:
#   JOBS  build parallelism (default: nproc, matching numPhysicalCPU() on CI)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

JOBS="${JOBS:-$(nproc)}"
WASM_OUT="${RUST_OMC_WASM_RUNTIME_OUT:-${REPO_ROOT}/runtime.wasm}"

if [ "${1:-}" = "--clean" ]; then
  # This is what standardSetup() runs on the CI agent before configuring.
  # It deletes every untracked and ignored file in the worktree and in every
  # submodule -- build_cmake/, build/, and any local scratch files included.
  # Opt-in only: a dev container is normally reused, and a full clean means a
  # full rebuild.
  echo "==> git clean -ffdx (worktree + submodules)"
  git clean -ffdx
  git submodule foreach --recursive git clean -ffdx
fi

# CI wraps the build in withSccache(['CARGO_PROFILE_RELEASE_OPT_LEVEL=2']):
# O3 is the default release opt-level, CI drops to O2 to cut build time. The
# rest of the sccache environment is set in devcontainer.json.
export CARGO_PROFILE_RELEASE_OPT_LEVEL=2

echo "==> configure (build_cmake)"
cmake -S . -B build_cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DOM_OMC_ENABLE_RUST=ON \
  -DRUST_OMC_CI=ON \
  -DOM_ENABLE_GUI_CLIENTS=OFF \
  -DRUST_OMC_SCRIPTING_API=ON \
  -DOM_USE_CCACHE=OFF \
  -DCMAKE_C_COMPILER_LAUNCHER=sccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=sccache \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_INSTALL_PREFIX=build \
  -DRUST_OMC_TIMINGS=ON \
  -DRUST_OMC_THREADS=4 \
  -DRUST_OMC_WASM_RUNTIME_OUT="${WASM_OUT}"

# `install` builds the whole tree (incl. rust_omc + the cdylib) and installs in
# one pass. Don't also pass rust_omc as a goal: recursive sub-makes would re-run
# the always-run cdylib custom target a second time (a redundant cargo pass).
echo "==> build + install"
cmake --build build_cmake --parallel "${JOBS}" --target install

build/bin/omc --version

echo "==> rust_wasm_runtime"
cmake --build build_cmake --parallel "${JOBS}" --target rust_wasm_runtime

echo "==> testsuite-depends"
cmake --build build_cmake --parallel "${JOBS}" --target testsuite-depends

echo "==> done; wasm runtime at ${WASM_OUT}"
