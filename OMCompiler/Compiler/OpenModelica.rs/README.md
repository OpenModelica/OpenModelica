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
has only 1 dense linear solver, a Newton non-linear solver (numerical
Jacobian), Euler, and dassl.
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

## Cross-compiling to Windows (x86_64-pc-windows-msvc)

The build *tools* (mmtorust, susan, scripting_api_gen) always run on and target
the host; only the omc *artifacts* (the cdylib + launcher, and the GUI clients)
are cross-compiled, with [`cargo-xwin`](https://github.com/rust-cross/cargo-xwin)
(clang-cl + lld-link against a cached MSVC CRT/SDK). Pass `-DRUST_OMC_TARGET`:

```bash
# One-time setup
rustup target add --toolchain nightly-2026-05-31 x86_64-pc-windows-msvc
cargo install cargo-xwin
# cc-rs invokes the LLVM archiver as `llvm-lib`; on a stock LLVM install only the
# versioned name exists, so expose it (adjust 21 to your llvm version):
ln -s "$(command -v llvm-lib-21)" ~/.local/bin/llvm-lib   # must be on PATH

cd ../../..
cmake -S . -B build-win -DOM_OMC_ENABLE_RUST=ON -DRUST_OMC_CI=ON \
      -DRUST_OMC_TARGET=x86_64-pc-windows-msvc -DOM_ENABLE_GUI_CLIENTS=OFF
cmake --build build-win --target install
# -> install_cmake/bin/{omc.exe, OpenModelicaCompiler.dll}
```

A cross build requires the release profile (the dev profile's cranelift backend
cannot target MSVC). The third-party native libraries the cdylib would otherwise
need are handled per-target in the crates so no MSVC-ABI build of them is
required: LAPACK/BLAS use the pure-Rust nalgebra fallback, libcurl is built from
source (`static-curl`), and libzmq is dropped (interactive `=zmq` mode
unavailable). libffi (for compile-time `external "C"` evaluation) *is* built: a
workspace `[patch.crates-io]` pointing libffi-sys at the `cargo-xwin-assembler`
branch of `github.com/sjoelund/libffi-rs` makes it assemble libffi's GNU-syntax
`win64.S` trampoline with clang-cl's integrated assembler instead of the MASM
`win64_intel.S` (which needs ml64, unavailable here) — see that crate's
`build/msvc.rs`. The Qt headers for the GUI clients are not wired
yet, so build with `-DOM_ENABLE_GUI_CLIENTS=OFF`.

The nalgebra LAPACK fallback can also be exercised on a native Linux build with
`-DRUST_OMC_PROFILE=release` plus the crate feature: build
`openmodelica_util`/the cdylib with `--features lapack-nalgebra` (or run the
testsuite against such a build) to validate it against system LAPACK.

### Cross-compiling the C/C++ runtime too (`.cmake/xwin-toolchain.cmake`)

The command above cross-compiles only the Rust omc; the C/C++ parts (3rdParty +
SimulationRuntime) still build for the host. To cross-compile those to MSVC as
well — reusing the *same* cargo-xwin CRT/SDK cache so the ABI matches — add the
toolchain file. It points clang-cl + lld-link at `~/.cache/cargo-xwin/xwin` and
forces the release CRT (xwin ships no debug CRT):

```bash
# Extra one-time setup (clang-cl's linker + resource compiler + archiver):
ln -s "$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin/rust-lld" \
      ~/.local/bin/lld-link                      # rust's bundled lld speaks lld-link
ln -s "$(command -v llvm-rc-21)" ~/.local/bin/llvm-rc
# (llvm-lib symlink from above is also required)

cmake -S . -B build-win \
      -DCMAKE_TOOLCHAIN_FILE=OMCompiler/Compiler/OpenModelica.rs/.cmake/xwin-toolchain.cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DOM_OMC_ENABLE_RUST=ON -DRUST_OMC_CI=ON \
      -DRUST_OMC_TARGET=x86_64-pc-windows-msvc -DOM_ENABLE_GUI_CLIENTS=OFF
```

The cargo-xwin sysroot must already exist (run the Rust-only cross build once, or
any `cargo xwin build`). The toolchain emits MSVC COFF objects and links with
lld-link (validated on 3rdParty/zlib + the configure below).

OpenModelica's CMake already supports MSVC, but expects the Windows dependency
libraries to be supplied — the xwin sysroot provides only the CRT/SDK. The
LAPACK/BLAS (OpenBLAS) and Boost deps are fetched automatically at configure
time by `.cmake/windows-deps.cmake` (auto-included when cross-compiling to
Windows; toggle with `OM_WINDOWS_FETCH_DEPS`): OpenBLAS as the prebuilt MSVC
release, Boost cross-built through vcpkg with the checked-in overlay triplet
`.cmake/x64-windows-xwin.cmake`. Only the downloaded artifacts are cached, under
`OM_WINDOWS_DOWNLOADS_DIR` — repoint it at an in-source directory to bundle them
into an offline source tarball. PThreads4W is the one dep still passed by hand
(its vcpkg port is nmake-only and cannot cross from Linux): build it from its
CMake fork with the toolchain and pass `-Dpthreads_DIR=<prefix>`.

```bash
# Disable the Fortran components: flang can compile Fortran to windows-msvc
# objects but cannot yet link them (no flang_rt/clang_rt.builtins for that target).
cmake -S . -B build-win \
  -DCMAKE_TOOLCHAIN_FILE=OMCompiler/Compiler/OpenModelica.rs/.cmake/xwin-toolchain.cmake \
  -DCMAKE_BUILD_TYPE=Release -Dpthreads_DIR=<pthreads4w-prefix> \
  -DOM_OMC_ENABLE_FORTRAN=OFF -DOM_OMC_ENABLE_MOO=OFF -DOM_OMC_ENABLE_OPTIMIZATION=OFF \
  -DOM_OMC_ENABLE_RUST=ON -DRUST_OMC_CI=ON \
  -DRUST_OMC_TARGET=x86_64-pc-windows-msvc -DOM_ENABLE_GUI_CLIENTS=OFF
```

Status: the C and C++ simulation runtimes now **compile** with clang-cl (final
link/install of the full distribution is the remaining work); see
`HANDOFF-windows-msvc.md`. The Rust-only cross build (earlier section) is
self-contained and needs none of these deps.

## Web bundle only (make all builds just the wasm):
```bash
cd ../../..
cmake -S . -B build-web -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DOM_OMC_WASM=ON -DRUST_OMC_WASM_MODE=web-release -DRUST_OMC_CI=ON
cmake --build build-web --target install
# To test locally
python3 -m http.server -d build-web/install_cmake/share/omc/web/ 8000
# Then open a browser at http://localhost:8000
```
