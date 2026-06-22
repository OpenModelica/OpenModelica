# OpenModelica Rust Target

Builds are done using cmake. It will compile its own version of Susan,
run that to create templates, then compile an executable that creates
the Qt API bindings using those templates.

Once that is done, mmtorust converts all the MetaModelica code into
Rust and starts compiling that.

Once compiled, it works just like the regular OMC (MMC), albeit a bit slower
(especially for array-heavy parts of the Backend).
The target uses 32-bit integers rather than 63-bit in MMC.
99.9% of the testsuite passes if ignoring the manual list of testcases failing
because of the 32-bit integer issue and some differences in columns for error-
messages.

There is also `--simCodeTarget=wasm-jit` which can be used with -d=gen
to JIT-compile functions, or simply with `simulate()` to skip code generation
and create a WASM-file that is loaded into memory to run the simulation.
The JIT compilation is limited at the moment (no external "C" functions yet although
that could possibly be done via FFI or Emscripten), and the simulation target
has only 1 dense linear solver, Euler, and dassl (no non-linear solvers).
The web target only supports the `wasm-jit` target (and does not compile the other
code generators into the image).

Performance when running the testsuite is within 90% of MMC for the release build.
Rust debug builds are very slow - only use them if you think compiling the
release takes too long (we could perhaps introduce a profile with -O1 as a middle
ground).

## Setup
```bash
apt install rustup binaryen
# We use this toolchain in Jenkins
rustup toolchain install nightly-2026-05-31 --profile minimal \
  --component rustc-codegen-cranelift-preview clippy rustfmt rust-analyzer \
  --target wasm32-unknown-unknown
# For the web targets:
rustup target add wasm32-unknown-unknown
export WASM_BINDGEN_VERSION=0.2.125 # See: ../../../.CI/cache/rust/Dockerfile in case this is stale
cargo install wasm-bindgen-cli --version "${WASM_BINDGEN_VERSION}"
```

## For development (debug builds compile faster but are much slower):
```bash
cd ../../..
cmake -S . -B build-cmake-rust -DOM_OMC_ENABLE_RUST=ON -DRUST_OMC_PROFILE=debug
cmake --build build-cmake-rust --target install -j16
cmake --build build-cmake-rust --target ctestsuite-depends -j16
cd build && ctest --output-on-failure --output-junit junit.xml # Note that tests take a while to compile - they use a different profile than the builds
```

## CI native build (release, no incremental for CI since it does not need the cache):
```bash
cd ../../..
cmake -S . -B build -DOM_OMC_ENABLE_RUST=ON -DRUST_OMC_CI=ON
cmake --build build --target install -j16
```

The native cargo builds link with `mold` by default when it is found on `PATH`
(`RUST_OMC_MOLD=ON`); pass `-DRUST_OMC_MOLD=OFF` to fall back to the toolchain's
default linker. mold must be reasonably recent — versions before 1.7 (e.g.
Ubuntu 22.04's 1.0.3) lack `--export-dynamic-symbol`, which the omc launcher
needs; the Jenkins image installs a pinned current mold for this (see
`../../../.CI/cache/rust/Dockerfile`).

Add `-DRUST_OMC_THREADS=N` to parallelise the rustc front-end (`-Zthreads=N`,
nightly only) — useful for the few huge generated crates that bottleneck the
otherwise-parallel `cargo` build.

## Web bundle only (make all builds just the wasm):
```bash
cd ../../..
cmake -S . -B build-web -DOM_OMC_WASM=ON -DRUST_OMC_WASM_MODE=web-release -DRUST_OMC_CI=ON
cmake --build build-web --target install
# To test locally
python3 -m http.server -d build-web/install_cmake/share/omc/web/ 8000
# Then open a browser at http://localhost:8000
```